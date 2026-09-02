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
import { NotificationsService } from '../notifications/notifications.service';
import { WhatsappService } from '../whatsapp/whatsapp.service';

function dateKey(d: Date) {
  return d.toISOString().slice(0, 10);
}

function rangesOverlap(
  aStart: Date,
  aEnd: Date | null,
  bStart: Date,
  bEnd: Date | null,
): boolean {
  const aS = new Date(aStart);
  aS.setUTCHours(0, 0, 0, 0);
  const aE = aEnd ? new Date(aEnd) : new Date(aS);
  aE.setUTCHours(23, 59, 59, 999);

  const bS = new Date(bStart);
  bS.setUTCHours(0, 0, 0, 0);
  const bE = bEnd ? new Date(bEnd) : new Date(bS);
  bE.setUTCHours(23, 59, 59, 999);

  return aS <= bE && bS <= aE;
}

@Injectable()
export class AssignmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
    private readonly notify: NotificationsService,
    private readonly whatsapp: WhatsappService,
  ) {}

  /**
   * Conflits multi-sites : affectations actives sur un autre site
   * dont la plage chevauche [startDate, endDate].
   */
  private async findMultiSiteConflicts(
    agentId: string,
    siteId: string,
    startDate: Date,
    endDate: Date | null,
  ) {
    const candidates = await this.prisma.assignment.findMany({
      where: {
        agentId,
        siteId: { not: siteId },
        status: {
          in: [
            AssignmentStatus.PENDING_CONFIRMATION,
            AssignmentStatus.CONFIRMED,
            AssignmentStatus.LOCKED,
          ],
        },
      },
      include: {
        site: { select: { id: true, name: true } },
      },
    });

    return candidates.filter((c) =>
      rangesOverlap(c.startDate, c.endDate, startDate, endDate),
    );
  }

  private async hasDepartOnDate(agentId: string, day: string) {
    const start = new Date(`${day}T00:00:00.000Z`);
    const end = new Date(`${day}T23:59:59.999Z`);
    const count = await this.prisma.pointage.count({
      where: {
        agentId,
        type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] },
        notedAt: { gte: start, lte: end },
      },
    });
    return count > 0;
  }

  async create(dto: CreateAssignmentDto, chefId: string) {
    const agent = await this.prisma.user.findUnique({
      where: { id: dto.agentId },
      include: { agentProfile: true },
    });

    if (!agent || agent.role !== Role.AGENT) {
      throw new NotFoundException('Agent introuvable');
    }

    const startDate = new Date(dto.startDate);
    const endDate = dto.endDate ? new Date(dto.endDate) : null;
    const startKey = dateKey(startDate);

    // —— Conflits multi-sites ——
    const conflicts = await this.findMultiSiteConflicts(
      dto.agentId,
      dto.siteId,
      startDate,
      endDate,
    );

    if (conflicts.length > 0) {
      const names = conflicts.map((c) => c.site.name).join(', ');
      const hasDepart = await this.hasDepartOnDate(dto.agentId, startKey);

      // Urgence : force + déjà pointé le jour de début
      if (dto.forceMultiSite && hasDepart) {
        // autorisé — on continue
      } else if (dto.forceMultiSite && !hasDepart) {
        throw new BadRequestException(
          `Urgence multi-sites refusée : l'agent n'a pas encore de pointage DEPART le ${startKey}. ` +
            `Conflit avec : ${names}`,
        );
      } else {
        throw new ConflictException({
          message: `Conflit multi-sites : agent déjà affecté sur ${names}`,
          code: 'MULTI_SITE_CONFLICT',
          conflicts: conflicts.map((c) => ({
            assignmentId: c.id,
            siteId: c.site.id,
            siteName: c.site.name,
            status: c.status,
            startDate: c.startDate,
            endDate: c.endDate,
          })),
          canForce: hasDepart,
          forceHint: hasDepart
            ? 'Agent déjà pointé ce jour — vous pouvez forcer (urgence multi-chantiers).'
            : 'Impossible de forcer tant que l\'agent n\'a pas de pointage DEPART ce jour-là (ou libérez-le d\'abord).',
        });
      }
    }

    // Verrouillage strict hors chevauchement de dates (ancien comportement)
    const existingLocked = await this.prisma.assignment.findFirst({
      where: {
        agentId: dto.agentId,
        isLocked: true,
        siteId: { not: dto.siteId },
        status: { in: [AssignmentStatus.CONFIRMED, AssignmentStatus.LOCKED] },
      },
      include: { site: { select: { name: true } } },
    });

    if (existingLocked && !dto.forceMultiSite) {
      // Si pas de chevauchement de dates, on laisse passer (missions successives)
      const overlaps = rangesOverlap(
        existingLocked.startDate,
        existingLocked.endDate,
        startDate,
        endDate,
      );
      if (overlaps) {
        throw new ConflictException(
          `Cet agent est déjà verrouillé sur ${existingLocked.site.name}`,
        );
      }
    }

    const unavailableDates: string[] =
      (agent.agentProfile?.unavailableDates as string[]) || [];
    const dayUnavailable = unavailableDates.includes(startKey);

    const assignment = (await this.prisma.assignment.create({
      data: {
        siteId: dto.siteId,
        agentId: dto.agentId,
        createdById: chefId,
        startDate,
        endDate,
        status: AssignmentStatus.PENDING_CONFIRMATION,
        isLocked: true,
        missionType: dto.missionType || 'TEMPORAIRE',
        routineDays: dto.routineDays
          ? (dto.routineDays as unknown as Prisma.InputJsonValue)
          : Prisma.JsonNull,
        fixedSalary: dto.fixedSalary || null,
      },
      include: {
        agent: {
          select: { id: true, firstName: true, lastName: true, phone: true },
        },
        site: { select: { id: true, name: true, type: true } },
      },
    })) as any;

    const siteName = assignment.site?.name || 'chantier';
    let body = dayUnavailable
      ? `Affectation sur ${siteName} un jour que vous aviez marqué indisponible — confirmez avant 22h`
      : `Nouvelle affectation sur ${siteName} — confirmez avant 22h`;

    if (dto.forceMultiSite && conflicts.length > 0) {
      body += ` (urgence multi-sites — aussi sur ${conflicts.map((c) => c.site.name).join(', ')})`;
    }

    await this.notify.push(dto.agentId, {
      title: 'Nouvelle affectation',
      body,
      type: 'assignment:new',
      data: {
        id: assignment.id,
        siteId: dto.siteId,
        dayUnavailable,
        multiSite: !!dto.forceMultiSite && conflicts.length > 0,
      },
    });

    this.notifications.notifyAssignment(dto.agentId, {
      id: assignment.id,
      site: assignment.site,
      startDate: assignment.startDate,
      endDate: assignment.endDate,
      status: assignment.status,
      message: body,
    });

    if (assignment.agent?.phone) {
      const date = assignment.startDate
        ? new Date(assignment.startDate).toLocaleDateString('fr-FR')
        : 'prochainement';
      const msg =
        `📋 *Convocation AS ONE*\n` +
        `Bonjour ${assignment.agent.firstName} ${assignment.agent.lastName},\n` +
        `Vous êtes convoqué(e) sur le chantier *${siteName}* à partir du *${date}*.\n` +
        `Veuillez confirmer votre présence dans l'application.`;
      this.whatsapp
        .sendMessage(chefId, assignment.agent.phone, msg)
        .catch(() => {});
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
      throw new BadRequestException(
        'Il est trop tard pour confirmer ou refuser (après 22h)',
      );
    }

    // Si confirmation : vérifier encore multi-sites
    if (accept) {
      const conflicts = await this.findMultiSiteConflicts(
        agentId,
        assignment.siteId,
        assignment.startDate,
        assignment.endDate,
      );
      // On autorise la confirmation même en multi-sites (le chef a déjà tranché)
      // mais on notifie les chefs des autres sites
      for (const c of conflicts) {
        if (c.createdById) {
          await this.notify.push(c.createdById, {
            title: 'Agent multi-sites',
            body: `Un agent confirmé aussi sur un autre chantier (chevauchement de dates).`,
            type: 'assignment:multi_site',
            data: {
              agentId,
              otherAssignmentId: assignmentId,
              siteId: assignment.siteId,
            },
          });
        }
      }
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
        : 'Un agent';
      await this.notify.push(assignment.createdById, {
        title: accept ? 'Affectation confirmée' : 'Affectation refusée',
        body: accept
          ? `${agentName} a confirmé l'affectation`
          : `${agentName} a refusé l'affectation`,
        type: 'assignment:response',
        data: { assignmentId, accepted: accept },
      });
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

  async requestTransfer(
    assignmentId: string,
    fromChefId: string,
    toChefId: string,
  ) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment || !assignment.isLocked) {
      throw new BadRequestException('Transfert impossible sur cette affectation');
    }

    const tr = await this.prisma.transferRequest.create({
      data: { assignmentId, fromChefId, toChefId },
    });

    await this.notify.push(toChefId, {
      title: 'Demande de transfert',
      body: "Un chef demande le transfert d'un agent vers vous",
      type: 'transfer:request',
      data: { transferId: tr.id, assignmentId },
    });

    return tr;
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
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
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
          where: {
            siteId_chefId: { siteId: tr.assignment.siteId, chefId },
          },
          create: { siteId: tr.assignment.siteId, chefId },
          update: {},
        }),
      ]);
      await this.notify.push(tr.fromChefId, {
        title: 'Transfert accepté',
        body: 'Votre demande de transfert a été acceptée',
        type: 'transfer:accepted',
        data: { transferId },
      });
      return { ok: true, status: 'ACCEPTED' };
    }

    await this.prisma.transferRequest.update({
      where: { id: transferId },
      data: { status: 'REJECTED', resolvedAt: new Date() },
    });
    await this.notify.push(tr.fromChefId, {
      title: 'Transfert refusé',
      body: 'Votre demande de transfert a été refusée',
      type: 'transfer:rejected',
      data: { transferId },
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

  async getAvailableAgents(siteId?: string) {
    const todayStr = new Date().toISOString().slice(0, 10);

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
            status: {
              in: [
                AssignmentStatus.PENDING_CONFIRMATION,
                AssignmentStatus.CONFIRMED,
                AssignmentStatus.LOCKED,
              ],
            },
          },
          select: {
            id: true,
            siteId: true,
            startDate: true,
            endDate: true,
            isLocked: true,
            status: true,
            site: { select: { id: true, name: true } },
          },
        },
      },
    });

    return agents.map((a) => {
      const ratings = a.ratingsReceived;
      const avgScore =
        ratings.length > 0
          ? ratings.reduce(
              (sum: number, r: { score: number }) => sum + r.score,
              0,
            ) / ratings.length
          : null;
      const daysWorked = new Set(
        a.pointages.map((p) => p.notedAt.toISOString().slice(0, 10)),
      ).size;

      const hasPointedToday = a.pointages.some(
        (p) => p.notedAt.toISOString().slice(0, 10) === todayStr,
      );

      // Autres sites actifs (chevauchement aujourd'hui ou plage ouverte)
      const otherSites = a.assignments.filter((asgn) => {
        if (siteId && asgn.siteId === siteId) return false;
        return rangesOverlap(
          asgn.startDate,
          asgn.endDate,
          new Date(`${todayStr}T00:00:00.000Z`),
          new Date(`${todayStr}T23:59:59.999Z`),
        );
      });

      const isLockedElsewhere = otherSites.length > 0 && !hasPointedToday;
      const canForceMultiSite = otherSites.length > 0 && hasPointedToday;

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
        canForceMultiSite,
        lockedOnSites: otherSites.map((s) => ({
          siteId: s.site.id,
          siteName: s.site.name,
          status: s.status,
        })),
        unavailableDates,
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

    const siteName = assignment.site?.name || 'chantier';
    await this.notify.push(assignment.agentId, {
      title: 'Libération de chantier',
      body: `Vous avez été libéré(e) de ${siteName}`,
      type: 'assignment:released',
      data: { assignmentId },
    });

    this.notifications.notifyAssignment(assignment.agentId, {
      id: assignmentId,
      status: updated.status,
      message: `Vous avez été libéré(e) de ${siteName}`,
    });

    if (assignment.agent?.phone) {
      const msg =
        `ℹ️ *AS ONE* : Vous avez été libéré(e) du chantier *${siteName}*.\n` +
        `Attendez une nouvelle convocation pour y retourner.`;
      this.whatsapp
        .sendMessage(chefId, assignment.agent.phone, msg)
        .catch(() => {});
    }

    return updated;
  }
}
