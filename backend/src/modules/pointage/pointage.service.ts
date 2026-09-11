import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { PointageType, AssignmentStatus } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { assertCanOperateOnSite } from '../../common/site-access';

function dayBoundsTogo(date = new Date()) {
  const key = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Lome',
  }).format(date);
  // bornes jour en UTC calées sur la clé calendaire Lomé
  const start = new Date(`${key}T00:00:00.000Z`);
  const end = new Date(`${key}T23:59:59.999Z`);
  return { start, end, key };
}

@Injectable()
export class PointageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
    private readonly notify: NotificationsService,
  ) {}

  /**
   * Résolution auto des conflits calendrier :
   * - DEPART / PRESENCE sur affectation PENDING → CONFIRMED + locked + confirmedAt
   * - DEPART / PRESENCE → retire le jour de unavailableDates (présence réelle)
   * - ABSENT sur PENDING → CANCELLED + unlock (pas de mission effective)
   * - Notifs agent (+ chef si auto-confirm / auto-annulation)
   */
  private async resolveCalendarConflicts(params: {
    agentId: string;
    siteId: string;
    siteName: string;
    type: PointageType;
    dateKey: string;
    assignment: {
      id: string;
      status: AssignmentStatus;
      createdById: string | null;
    } | null;
  }) {
    const { agentId, siteName, type, dateKey, assignment } = params;
    const isPresence =
      type === PointageType.DEPART || type === PointageType.PRESENCE_PERMANENCE;

    let autoConfirmed = false;
    let autoCancelled = false;
    let clearedUnavailability = false;

    // 1) Affectation PENDING
    if (assignment?.status === AssignmentStatus.PENDING_CONFIRMATION) {
      if (isPresence) {
        await this.prisma.assignment.update({
          where: { id: assignment.id },
          data: {
            status: AssignmentStatus.CONFIRMED,
            confirmedAt: new Date(),
            isLocked: true,
            refusedAt: null,
          },
        });
        autoConfirmed = true;

        await this.notify.push(agentId, {
          title: 'Affectation confirmée automatiquement',
          body: `Votre présence sur ${siteName} le ${dateKey} a validé l'affectation.`,
          type: 'assignment:auto_confirmed',
          data: {
            assignmentId: assignment.id,
            siteId: params.siteId,
            date: dateKey,
          },
        });

        if (assignment.createdById) {
          await this.notify.push(assignment.createdById, {
            title: 'Affectation auto-confirmée',
            body: `Pointage enregistré → affectation confirmée sur ${siteName} (${dateKey}).`,
            type: 'assignment:auto_confirmed',
            data: {
              assignmentId: assignment.id,
              agentId,
              date: dateKey,
            },
          });
        }
      } else if (type === PointageType.ABSENT) {
        await this.prisma.assignment.update({
          where: { id: assignment.id },
          data: {
            status: AssignmentStatus.CANCELLED,
            isLocked: false,
          },
        });
        autoCancelled = true;

        await this.notify.push(agentId, {
          title: 'Affectation annulée',
          body: `Absence enregistrée le ${dateKey} sur ${siteName} — l'affectation en attente est annulée.`,
          type: 'assignment:auto_cancelled',
          data: {
            assignmentId: assignment.id,
            siteId: params.siteId,
            date: dateKey,
          },
        });

        if (assignment.createdById) {
          await this.notify.push(assignment.createdById, {
            title: 'Affectation auto-annulée',
            body: `Absence pointée → affectation en attente annulée sur ${siteName} (${dateKey}).`,
            type: 'assignment:auto_cancelled',
            data: {
              assignmentId: assignment.id,
              agentId,
              date: dateKey,
            },
          });
        }
      }
    }

    // 2) Indispo déclarée vs présence réelle → le terrain gagne
    if (isPresence) {
      const profile = await this.prisma.agentProfile.findUnique({
        where: { userId: agentId },
      });
      if (profile) {
        const unavailableDates: string[] =
          (profile.unavailableDates as string[]) || [];
        if (unavailableDates.includes(dateKey)) {
          const next = unavailableDates.filter((d) => d !== dateKey);
          await this.prisma.agentProfile.update({
            where: { userId: agentId },
            data: { unavailableDates: next },
          });
          clearedUnavailability = true;

          await this.notify.push(agentId, {
            title: 'Indisponibilité levée',
            body: `Présence pointée le ${dateKey} : le jour n'est plus marqué indisponible.`,
            type: 'availability:cleared',
            data: { date: dateKey, siteId: params.siteId },
          });
        }
      }
    }

    return { autoConfirmed, autoCancelled, clearedUnavailability };
  }

  async create(dto: CreatePointageDto, createdById: string) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');
    await assertCanOperateOnSite(this.prisma, dto.siteId, createdById);

    const type = dto.type ?? PointageType.DEPART;
    const notedDate = dto.notedAt ? new Date(dto.notedAt) : new Date();
    const { start, end, key } = dayBoundsTogo(notedDate);
    const results: Array<Record<string, unknown>> = [];

    for (const agentId of dto.agentIds) {
      const existing = await this.prisma.pointage.findFirst({
        where: {
          agentId,
          siteId: dto.siteId,
          type,
          notedAt: { gte: start, lte: end },
        },
      });

      if (existing) {
        results.push({
          agentId,
          status: 'skipped',
          reason:
            type === PointageType.ABSENT
              ? `Déjà marqué absent le ${key}`
              : `Départ déjà enregistré le ${key}`,
        });
        continue;
      }

      const assignment = await this.prisma.assignment.findFirst({
        where: {
          agentId,
          siteId: dto.siteId,
          status: {
            in: [
              AssignmentStatus.CONFIRMED,
              AssignmentStatus.LOCKED,
              AssignmentStatus.PENDING_CONFIRMATION,
            ],
          },
        },
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          status: true,
          createdById: true,
        },
      });

      const resolution = await this.resolveCalendarConflicts({
        agentId,
        siteId: dto.siteId,
        siteName: site.name,
        type,
        dateKey: key,
        assignment,
      });

      // Après annulation auto, ne plus lier le pointage à l'assignment cancelled
      const assignmentIdForPointage =
        resolution.autoCancelled ? null : (assignment?.id ?? null);

      const pointage = await this.prisma.pointage.create({
        data: {
          siteId: dto.siteId,
          agentId,
          assignmentId: assignmentIdForPointage,
          type,
          photoUrl: dto.photoUrl,
          latitude: dto.latitude,
          longitude: dto.longitude,
          createdById,
          notedAt: start,
        },
        include: {
          agent: {
            select: { id: true, firstName: true, lastName: true, phone: true },
          },
        },
      });

      results.push({
        agentId,
        status: 'ok',
        pointage,
        autoConfirmed: resolution.autoConfirmed,
        autoCancelled: resolution.autoCancelled,
        clearedUnavailability: resolution.clearedUnavailability,
      });

      const isPast = key !== dayBoundsTogo().key;
      const dateLabel = new Date(`${key}T12:00:00Z`).toLocaleDateString('fr-FR');

      let message: string;
      if (type === PointageType.ABSENT) {
        message = `Vous avez été marqué(e) absent(e) le ${dateLabel} sur ${site.name}`;
        if (resolution.autoCancelled) {
          message += ' — affectation en attente annulée.';
        }
      } else if (isPast) {
        message = `Votre départ du ${dateLabel} a été enregistré sur ${site.name}`;
        if (resolution.autoConfirmed) {
          message += ' — affectation confirmée automatiquement.';
        }
      } else {
        message = `Votre départ a été enregistré sur ${site.name}`;
        if (resolution.autoConfirmed) {
          message += ' — affectation confirmée automatiquement.';
        }
      }

      await this.notify.push(agentId, {
        title:
          type === PointageType.ABSENT
            ? 'Absence enregistrée'
            : 'Pointage enregistré',
        body: message,
        type: type === PointageType.ABSENT ? 'pointage:absent' : 'pointage:depart',
        data: {
          siteId: dto.siteId,
          type,
          date: key,
          autoConfirmed: resolution.autoConfirmed,
          autoCancelled: resolution.autoCancelled,
        },
      });

      // Compat écouteurs legacy
      this.notifications.notifyPointage(agentId, {
        siteId: dto.siteId,
        type,
        date: key,
        message,
      });
    }

    return {
      siteId: dto.siteId,
      type,
      results,
      successCount: results.filter((r) => r.status === 'ok').length,
      skippedCount: results.filter((r) => r.status === 'skipped').length,
      autoConfirmedCount: results.filter((r) => r.autoConfirmed === true).length,
      autoCancelledCount: results.filter((r) => r.autoCancelled === true).length,
    };
  }

  async list(filters?: { siteId?: string; date?: string; type?: string }) {
    const where: Record<string, unknown> = {};
    if (filters?.siteId) where.siteId = filters.siteId;
    if (filters?.type) where.type = filters.type;
    if (filters?.date) {
      const { start, end } = dayBoundsTogo(new Date(filters.date));
      where.notedAt = { gte: start, lte: end };
    }

    return this.prisma.pointage.findMany({
      where,
      include: {
        agent: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
            role: true,
          },
        },
        site: { select: { id: true, name: true, type: true } },
      },
      orderBy: { notedAt: 'desc' },
      take: 300,
    });
  }

  async getBySite(siteId: string, date?: string) {
    return this.list({ siteId, date });
  }

  async getByAgent(agentId: string, limit = 60) {
    return this.prisma.pointage.findMany({
      where: { agentId },
      include: {
        site: { select: { id: true, name: true, type: true } },
      },
      orderBy: { notedAt: 'desc' },
      take: limit,
    });
  }
}
