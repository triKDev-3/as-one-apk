import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { AssignmentStatus, Role, Prisma } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { WhatsappService } from '../whatsapp/whatsapp.service';

@Injectable()
export class AssignmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
    private readonly whatsapp: WhatsappService,
  ) {}

  async create(dto: CreateAssignmentDto, chefId: string) {
    const existingLocked = await this.prisma.assignment.findFirst({
      where: {
        agentId: dto.agentId,
        isLocked: true,
        status: { in: [AssignmentStatus.CONFIRMED, AssignmentStatus.LOCKED] },
      },
    });

    if (existingLocked) {
      throw new ConflictException('Cet agent est déjà verrouillé sur un autre chantier');
    }

    const agent = await this.prisma.user.findUnique({
      where: { id: dto.agentId },
      include: { agentProfile: true },
    });

    if (!agent || agent.role !== Role.AGENT) {
      throw new NotFoundException('Agent introuvable');
    }

    // Toujours confirmation jusqu'à 22h — encore plus si indisponible global ou jour marqué
    const unavailableDates: string[] =
      (agent.agentProfile?.unavailableDates as string[]) || [];
    const startKey = new Date(dto.startDate).toISOString().slice(0, 10);
    const dayUnavailable = unavailableDates.includes(startKey);
    const needsConfirmation =
      !agent.agentProfile?.isAvailable || dayUnavailable || true;

    const assignment = await this.prisma.assignment.create({
      data: {
        siteId: dto.siteId,
        agentId: dto.agentId,
        createdById: chefId,
        startDate: new Date(dto.startDate),
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        status: needsConfirmation
          ? AssignmentStatus.PENDING_CONFIRMATION
          : AssignmentStatus.CONFIRMED,
        isLocked: true,
        missionType: dto.missionType || 'TEMPORAIRE',
        routineDays: dto.routineDays
          ? (dto.routineDays as unknown as Prisma.InputJsonValue)
          : Prisma.JsonNull,
        fixedSalary: dto.fixedSalary || null,
      },
      include: {
        agent: { select: { id: true, firstName: true, lastName: true, phone: true } },
        site: { select: { id: true, name: true, type: true } },
      },
    }) as any;

    this.notifications.notifyAssignment(dto.agentId, {
      id: assignment.id,
      site: (assignment as any).site,
      startDate: assignment.startDate,
      endDate: assignment.endDate,
      status: assignment.status,
      message: dayUnavailable
        ? 'Affectation sur un jour que vous aviez marqué indisponible — confirmez avant 22h'
        : 'Nouvelle affectation — confirmez avant 22h',
    });

    if (assignment.agent?.phone) {
      const siteName = assignment.site?.name || 'chantier';
      const date = assignment.startDate
        ? new Date(assignment.startDate).toLocaleDateString('fr-FR')
        : 'prochainement';
      const msg =
        `📋 *Convocation AS ONE*\n` +
        `Bonjour ${assignment.agent.firstName} ${assignment.agent.lastName},\n` +
        `Vous êtes convoqué(e) sur le chantier *${siteName}* à partir du *${date}*.\n` +
        `Veuillez confirmer votre présence dans l'application.`;
      this.whatsapp.sendMessage(chefId, assignment.agent.phone, msg).catch(() => {});
    }

    return assignment;
  }

  async confirmOrRefuse(assignmentId: string, agentId: string, accept: boolean) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment || assignment.agentId !== agentId) {
      throw new ForbiddenException();
    }

    if (assignment.status !== AssignmentStatus.PENDING_CONFIRMATION) {
      throw new BadRequestException('Cette affectation ne peut plus être modifiée');
    }

    const hourTogo = Number(
      new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Africa/Lome',
        hour: 'numeric',
        hour12: false,
      }).format(new Date()),
    );
    if ((hourTogo === 24 ? 0 : hourTogo) >= 22) {
      throw new BadRequestException('Il est trop tard pour confirmer ou refuser (après 22h)');
    }

    const updated = await this.prisma.assignment.update({
      where: { id: assignmentId },
      data: {
        status: accept ? AssignmentStatus.CONFIRMED : AssignmentStatus.REFUSED,
        confirmedAt: accept ? new Date() : null,
        refusedAt: accept ? null : new Date(),
        isLocked: accept,
      },
      include: {
        agent: { select: { firstName: true, lastName: true } },
      },
    });

    if (assignment.createdById) {
      const agentName = updated.agent
        ? `${updated.agent.firstName} ${updated.agent.lastName}`
        : undefined;
      this.notifications.notifyAssignmentResponse(assignment.createdById, {
        assignmentId,
        accepted: accept,
        agentName,
      });
    }

    return updated;
  }

  async getBySite(siteId: string) {
    return this.prisma.assignment.findMany({
      where: {
        siteId,
        status: {
          in: [
            AssignmentStatus.CONFIRMED,
            AssignmentStatus.LOCKED,
            AssignmentStatus.PENDING_CONFIRMATION,
          ],
        },
      },
      include: {
        agent: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
            rankingScore: true,
            agentProfile: {
              select: { isAvailable: true, unavailableDates: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async requestTransfer(assignmentId: string, fromChefId: string, toChefId: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment || !assignment.isLocked) {
      throw new BadRequestException('Transfert impossible sur cette affectation');
    }

    return this.prisma.transferRequest.create({
      data: { assignmentId, fromChefId, toChefId },
    });
  }

  async listPendingTransfers(chefId: string) {
    return this.prisma.transferRequest.findMany({
      where: {
        status: 'PENDING',
        OR: [{ toChefId: chefId }, { fromChefId: chefId }],
      },
      include: {
        assignment: {
          include: {
            agent: {
              select: { id: true, firstName: true, lastName: true, phone: true },
            },
            site: { select: { id: true, name: true } },
          },
        },
        fromChef: { select: { id: true, firstName: true, lastName: true } },
        toChef: { select: { id: true, firstName: true, lastName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async resolveTransfer(transferId: string, chefId: string, accept: boolean) {
    const tr = await this.prisma.transferRequest.findUnique({
      where: { id: transferId },
      include: { assignment: true },
    });
    if (!tr || tr.status !== 'PENDING') {
      throw new BadRequestException('Demande de transfert invalide');
    }
    if (tr.toChefId !== chefId) {
      throw new ForbiddenException('Seul le chef destinataire peut répondre');
    }

    if (accept) {
      await this.prisma.$transaction([
        this.prisma.transferRequest.update({
          where: { id: transferId },
          data: { status: 'ACCEPTED', resolvedAt: new Date() },
        }),
        this.prisma.assignment.update({
          where: { id: tr.assignmentId },
          data: { createdById: chefId },
        }),
        this.prisma.siteChef.upsert({
          where: { siteId_chefId: { siteId: tr.assignment.siteId, chefId } },
          create: { siteId: tr.assignment.siteId, chefId },
          update: {},
        }),
      ]);
      return { ok: true, status: 'ACCEPTED' };
    }

    await this.prisma.transferRequest.update({
      where: { id: transferId },
      data: { status: 'REJECTED', resolvedAt: new Date() },
    });
    return { ok: true, status: 'REJECTED' };
  }

  async listChefs() {
    return this.prisma.user.findMany({
      where: { role: Role.CHEF, isActive: true },
      select: { id: true, firstName: true, lastName: true, phone: true },
      orderBy: { lastName: 'asc' },
    });
  }

  /**
   * Pool agents pour composition : disponibilité globale + jours indispos + jours travaillés (DEPART).
   * Le chef VOIT les jours marqués indisponibles mais peut quand même assigner / pointer.
   */
  async getAvailableAgents(siteId?: string) {
    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      include: {
        agentProfile: {
          select: { isAvailable: true, unavailableDates: true },
        },
        ratingsReceived: { select: { score: true } },
        pointages: {
          where: { type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] } },
          select: { notedAt: true },
        },
        assignments: {
          where: {
            isLocked: true,
            status: {
              in: [AssignmentStatus.CONFIRMED, AssignmentStatus.LOCKED],
            },
          },
          select: { id: true, siteId: true },
        },
      },
    });

    return agents.map((a) => {
      const ratings = a.ratingsReceived;
      const avgScore =
        ratings.length > 0
          ? ratings.reduce((sum: number, r: { score: number }) => sum + r.score, 0) /
            ratings.length
          : null;
      const daysWorked = new Set(
        a.pointages.map((p) => p.notedAt.toISOString().slice(0, 10)),
      ).size;
      const todayStr = new Date().toISOString().slice(0, 10);
      const hasPointedToday = a.pointages.some(
        (p) => p.notedAt.toISOString().slice(0, 10) === todayStr,
      );
      const isLockedElsewhere =
        a.assignments.some(
          (asgn: { siteId: string }) => siteId && asgn.siteId !== siteId,
        ) && !hasPointedToday;

      const unavailableDates: string[] =
        (a.agentProfile?.unavailableDates as string[]) || [];

      return {
        id: a.id,
        firstName: a.firstName,
        lastName: a.lastName,
        phone: a.phone,
        contractType: a.contractType,
        rankingScore: a.rankingScore,
        avgScore,
        daysWorked,
        isAvailable: a.agentProfile?.isAvailable ?? true,
        isLockedElsewhere,
        unavailableDates,
        /** true si le jour calendaire d'aujourd'hui est marqué indispo */
        isUnavailableToday: unavailableDates.includes(todayStr),
      };
    });
  }

  async releaseAgent(assignmentId: string, chefId: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
      include: {
        agent: { select: { firstName: true, lastName: true, phone: true } },
        site: { select: { name: true } },
      },
    });

    if (!assignment) throw new NotFoundException('Affectation introuvable');
    if (assignment.createdById !== chefId)
      throw new ForbiddenException('Action non autorisée');

    const updated = await this.prisma.assignment.update({
      where: { id: assignmentId },
      data: { isLocked: false, status: AssignmentStatus.CANCELLED },
    });

    this.notifications.notifyAssignment(assignment.agentId, {
      id: assignmentId,
      status: updated.status,
      message: 'Vous avez été libéré(e) de ce chantier par votre chef.',
    });

    if (assignment.agent?.phone) {
      const siteName = assignment.site?.name || 'chantier';
      const msg =
        `ℹ️ *AS ONE* : Vous avez été libéré(e) du chantier *${siteName}*.\n` +
        `Attendez une nouvelle convocation pour y retourner.`;
      this.whatsapp.sendMessage(chefId, assignment.agent.phone, msg).catch(() => {});
    }

    return updated;
  }
}
