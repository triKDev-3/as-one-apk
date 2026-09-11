import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  AgentType,
  AssignmentStatus,
  Role,
} from '@prisma/client';
import { assertCanOperateOnSite } from '../../common/site-access';

@Injectable()
export class PermanenceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notify: NotificationsService,
  ) {}

  /**
   * Crée un planning de permanence + créneaux.
   * body: { siteId, title?, workDaysPerWeek, slots: [{ startTime, endTime, salary, requiredAgents, label? }] }
   */
  async createSchedule(
    chefId: string,
    body: {
      siteId: string;
      title?: string;
      workDaysPerWeek?: number;
      slots: Array<{
        startTime: string;
        endTime: string;
        salary: number;
        requiredAgents?: number;
        label?: string;
      }>;
    },
  ) {
    const site = await this.prisma.site.findUnique({ where: { id: body.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');
    await assertCanOperateOnSite(this.prisma, body.siteId, chefId);
    if (site.type !== 'PERMANENCE' && site.type !== 'ROUTINE') {
      // on autorise aussi CHANTIER transformé en permanence opérationnelle
    }
    if (!body.slots?.length) {
      throw new BadRequestException('Au moins un créneau (intervalle) est requis');
    }

    // Stockage JSON si modèles Prisma pas encore migrés — fallback via raw tables would fail
    // On utilise tables si présentes ; sinon on lève message clair
    try {
      const schedule = await (this.prisma as any).permanenceSchedule.create({
        data: {
          siteId: body.siteId,
          createdById: chefId,
          title: body.title || `Permanence ${site.name}`,
          workDaysPerWeek: body.workDaysPerWeek ?? 6,
          status: 'DRAFT',
          slots: {
            create: body.slots.map((s) => ({
              startTime: s.startTime,
              endTime: s.endTime,
              salary: s.salary,
              requiredAgents: s.requiredAgents ?? 1,
              label: s.label || `${s.startTime} – ${s.endTime}`,
            })),
          },
        },
        include: { slots: true, site: { select: { id: true, name: true } } },
      });
      return schedule;
    } catch (e: any) {
      throw new BadRequestException(
        'Tables permanence absentes. Exécutez la migration Prisma (permanence_offers). ' +
          (e?.message || ''),
      );
    }
  }

  async listBySite(siteId: string) {
    try {
      return await (this.prisma as any).permanenceSchedule.findMany({
        where: { siteId },
        include: {
          slots: {
            include: {
              applications: {
                include: {
                  agent: {
                    select: {
                      id: true,
                      firstName: true,
                      lastName: true,
                      phone: true,
                      agentType: true,
                    },
                  },
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });
    } catch {
      return [];
    }
  }

  /** Publie l'offre à tous les agents (surtout temporaires). */
  async publish(scheduleId: string, chefId: string) {
    const schedule = await (this.prisma as any).permanenceSchedule.findUnique({
      where: { id: scheduleId },
      include: {
        slots: true,
        site: { select: { name: true } },
      },
    });
    if (!schedule) throw new NotFoundException('Planning introuvable');
    await assertCanOperateOnSite(this.prisma, schedule.siteId, chefId);

    const updated = await (this.prisma as any).permanenceSchedule.update({
      where: { id: scheduleId },
      data: { status: 'PUBLISHED', publishedAt: new Date() },
    });

    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      select: { id: true, agentType: true },
    });

    const slotsSummary = schedule.slots
      .map(
        (s: any) =>
          `${s.startTime}-${s.endTime} (${Number(s.salary)} F · ${s.requiredAgents} poste(s))`,
      )
      .join(' · ');

    await this.notify.pushMany(
      agents.map((a) => a.id),
      {
        title: 'Offre de permanence',
        body: `${schedule.site.name} : ${slotsSummary}. Consultez et postulez dans l'app.`,
        type: 'offer:published',
        data: {
          scheduleId,
          siteId: schedule.siteId,
        },
      },
    );

    return updated;
  }

  /** Offres ouvertes visibles par l'agent. */
  async listOpenOffers() {
    try {
      return await (this.prisma as any).permanenceSchedule.findMany({
        where: { status: 'PUBLISHED' },
        include: {
          site: { select: { id: true, name: true, address: true, type: true } },
          slots: true,
        },
        orderBy: { publishedAt: 'desc' },
      });
    } catch {
      return [];
    }
  }

  async apply(slotId: string, agentId: string) {
    const slot = await (this.prisma as any).permanenceSlot.findUnique({
      where: { id: slotId },
      include: { schedule: true },
    });
    if (!slot) throw new NotFoundException('Créneau introuvable');
    if (slot.schedule.status !== 'PUBLISHED') {
      throw new BadRequestException('Cette offre n\'est plus ouverte');
    }

    const existing = await (this.prisma as any).permanenceApplication.findUnique({
      where: { slotId_agentId: { slotId, agentId } },
    });
    if (existing) {
      throw new BadRequestException('Vous avez déjà postulé à ce créneau');
    }

    const app = await (this.prisma as any).permanenceApplication.create({
      data: { slotId, agentId, status: 'PENDING' },
      include: {
        agent: { select: { firstName: true, lastName: true } },
        slot: { include: { schedule: { include: { site: true } } } },
      },
    });

    const chefId = slot.schedule.createdById as string;
    const name = `${app.agent.firstName} ${app.agent.lastName}`;
    await this.notify.push(chefId, {
      title: 'Candidature permanence',
      body: `${name} postule pour ${slot.startTime}-${slot.endTime} sur ${app.slot.schedule.site.name}`,
      type: 'offer:application',
      data: { applicationId: app.id, slotId, agentId },
    });

    return app;
  }

  async resolveApplication(
    applicationId: string,
    chefId: string,
    accept: boolean,
    rejectMessage?: string,
  ) {
    const app = await (this.prisma as any).permanenceApplication.findUnique({
      where: { id: applicationId },
      include: {
        agent: true,
        slot: {
          include: {
            schedule: { include: { site: true } },
          },
        },
      },
    });
    if (!app) throw new NotFoundException();
    await assertCanOperateOnSite(
      this.prisma,
      app.slot.schedule.siteId,
      chefId,
    );
    if (app.status !== 'PENDING') {
      throw new BadRequestException('Candidature déjà traitée');
    }

    if (!accept) {
      const polite =
        rejectMessage?.trim() ||
        'Merci pour votre candidature. Malheureusement ce créneau a été attribué à un autre profil. Nous vous recontacterons pour de prochaines opportunités.';

      const updated = await (this.prisma as any).permanenceApplication.update({
        where: { id: applicationId },
        data: {
          status: 'REJECTED',
          rejectMessage: polite,
          resolvedAt: new Date(),
        },
      });

      await this.notify.push(app.agentId, {
        title: 'Candidature non retenue',
        body: polite,
        type: 'offer:rejected',
        data: { applicationId },
      });

      return updated;
    }

    // Acceptation → assignment permanente + passage TEMPORAIRE → PERMANENT
    const result = await this.prisma.$transaction(async (tx) => {
      const updated = await (tx as any).permanenceApplication.update({
        where: { id: applicationId },
        data: { status: 'ACCEPTED', resolvedAt: new Date() },
      });

      await tx.assignment.create({
        data: {
          siteId: app.slot.schedule.siteId,
          agentId: app.agentId,
          createdById: chefId,
          status: AssignmentStatus.CONFIRMED,
          startDate: new Date(),
          endDate: null,
          isLocked: true,
          missionType: 'PERMANENTE',
          fixedSalary: app.slot.salary,
          confirmedAt: new Date(),
        },
      });

      if (app.agent.agentType !== AgentType.PERMANENT) {
        await tx.user.update({
          where: { id: app.agentId },
          data: {
            agentType: AgentType.PERMANENT,
            contractType: 'PERMANENT',
          },
        });
      }

      return updated;
    });

    await this.notify.push(app.agentId, {
      title: 'Candidature acceptée',
      body: `Félicitations ! Vous êtes retenu(e) pour le créneau ${app.slot.startTime}-${app.slot.endTime} sur ${app.slot.schedule.site.name}. Bienvenue en permanence.`,
      type: 'offer:accepted',
      data: { applicationId },
    });

    return result;
  }

  async myApplications(agentId: string) {
    try {
      return await (this.prisma as any).permanenceApplication.findMany({
        where: { agentId },
        include: {
          slot: {
            include: {
              schedule: {
                include: { site: { select: { name: true } } },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });
    } catch {
      return [];
    }
  }
}
