import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteDto } from './dto/update-site.dto';
import { AssignmentStatus, Role, Prisma } from '@prisma/client';

@Injectable()
export class SitesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateSiteDto, createdById: string) {
    return this.prisma.site.create({
      data: {
        name: dto.name,
        type: dto.type,
        address: dto.address,
        location: dto.location,
        startDate: dto.startDate ? new Date(dto.startDate) : null,
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        dailyRate: dto.dailyRate,
        nightRate: dto.nightRate ?? 4500,
        sundayRate: dto.sundayRate ?? 5000,
        bonusAmount: dto.bonusAmount,
        monthlySalary: dto.monthlySalary,
        fixedAmount: dto.fixedAmount,
        createdById,
      },
    });
  }

  async update(id: string, dto: UpdateSiteDto) {
    await this.findOne(id);

    if (dto.isActive === false) {
      await this.assertCanDeactivate(id);
    }

    return this.prisma.site.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.type !== undefined ? { type: dto.type } : {}),
        ...(dto.address !== undefined ? { address: dto.address } : {}),
        ...(dto.location !== undefined ? { location: dto.location } : {}),
        ...(dto.startDate !== undefined
          ? { startDate: dto.startDate ? new Date(dto.startDate) : null }
          : {}),
        ...(dto.endDate !== undefined
          ? { endDate: dto.endDate ? new Date(dto.endDate) : null }
          : {}),
        ...(dto.dailyRate !== undefined ? { dailyRate: dto.dailyRate } : {}),
        ...(dto.nightRate !== undefined ? { nightRate: dto.nightRate } : {}),
        ...(dto.sundayRate !== undefined ? { sundayRate: dto.sundayRate } : {}),
        ...(dto.bonusAmount !== undefined ? { bonusAmount: dto.bonusAmount } : {}),
        ...(dto.monthlySalary !== undefined
          ? { monthlySalary: dto.monthlySalary }
          : {}),
        ...(dto.fixedAmount !== undefined ? { fixedAmount: dto.fixedAmount } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
      },
    });
  }

  async softDelete(id: string) {
    await this.findOne(id);
    await this.assertCanDeactivate(id);
    return this.prisma.site.update({
      where: { id },
      data: { isActive: false },
    });
  }

  private async assertCanDeactivate(siteId: string) {
    const [
      assignments,
      pointages,
      incidents,
      fiches,
      tasks,
      reports,
      schedules,
      movements,
    ] = await Promise.all([
      this.prisma.assignment.count({ where: { siteId } }),
      this.prisma.pointage.count({ where: { siteId } }),
      this.prisma.incident.count({ where: { siteId } }),
      this.prisma.materialFiche.count({ where: { siteId } }),
      this.prisma.siteTask.count({ where: { siteId } }),
      this.prisma.siteReport.count({ where: { siteId } }),
      this.prisma.permanenceSchedule.count({ where: { siteId } }),
      this.prisma.materialMovement.count({ where: { siteId } }),
    ]);

    const total =
      assignments +
      pointages +
      incidents +
      fiches +
      tasks +
      reports +
      schedules +
      movements;

    if (total > 0) {
      const details: string[] = [];
      if (assignments) details.push(`${assignments} affectation(s)`);
      if (pointages) details.push(`${pointages} pointage(s)`);
      if (incidents) details.push(`${incidents} incident(s)`);
      if (fiches) details.push(`${fiches} fiche(s) matériel`);
      if (tasks) details.push(`${tasks} tâche(s)`);
      if (reports) details.push(`${reports} rapport(s)`);
      if (schedules) details.push(`${schedules} planning(s) permanence`);
      if (movements) details.push(`${movements} mouvement(s) matériel`);

      throw new BadRequestException(
        `Impossible de supprimer ou désactiver ce site : des actions ont déjà été menées (${details.join(', ')}). ` +
          `Utilisez la clôture Direction après rapport de fin de chantier.`,
      );
    }
  }

  async findAll(
    type?: string,
    userId?: string,
    role?: string,
    all?: boolean,
    includeInactive = false,
  ) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter =
      isFiltered && userId ? { chefs: { some: { chefId: userId } } } : {};

    const sites = await this.prisma.site.findMany({
      where: {
        ...(includeInactive ? {} : { isActive: true }),
        ...(type ? { type: type as any } : {}),
        ...siteFilter,
      },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                isActive: true,
              },
            },
          },
        },
        _count: {
          select: {
            assignments: true,
            pointages: true,
            incidents: true,
            materialFiches: true,
            siteTasks: true,
            reports: true,
            permanenceSchedules: true,
            materials: true,
          },
        },
      },
      orderBy: [{ isActive: 'desc' }, { name: 'asc' }],
    });

    const enriched = await Promise.all(
      sites.map(async (s) => {
        const activeAssignments = await this.prisma.assignment.findMany({
          where: {
            siteId: s.id,
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
            status: true,
            startDate: true,
            endDate: true,
            agent: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
          take: 50,
        });

        const pendingReport = await this.prisma.siteReport.findFirst({
          where: { siteId: s.id, status: 'PENDING_ADMIN' },
          orderBy: { closedAt: 'desc' },
          select: { id: true, status: true, closedAt: true },
        });

        const lastReport = await this.prisma.siteReport.findFirst({
          where: { siteId: s.id },
          orderBy: { closedAt: 'desc' },
          select: { id: true, status: true, closedAt: true, summary: true },
        });

        const c = s._count;
        const hasAnyHistory =
          c.assignments > 0 ||
          c.pointages > 0 ||
          c.incidents > 0 ||
          c.materialFiches > 0 ||
          c.siteTasks > 0 ||
          c.reports > 0 ||
          c.permanenceSchedules > 0 ||
          c.materials > 0;

        return {
          ...s,
          activeAgentsCount: activeAssignments.length,
          canDelete: !hasAnyHistory,
          canRelaunch: !s.isActive || s.type === 'PERMANENCE',
          pendingAdminDecision: pendingReport != null,
          pendingReport,
          lastReport,
          historyCounts: {
            assignments: c.assignments,
            pointages: c.pointages,
            incidents: c.incidents,
            tasks: c.siteTasks,
            reports: c.reports,
            material: c.materialFiches + c.materials,
          },
          activeAssignments: activeAssignments.map((a) => ({
            id: a.id,
            status: a.status,
            startDate: a.startDate,
            endDate: a.endDate,
            agentName: `${a.agent.firstName} ${a.agent.lastName}`.trim(),
            agentId: a.agent.id,
          })),
        };
      }),
    );

    return enriched;
  }

  async findOne(id: string) {
    const site = await this.prisma.site.findUnique({
      where: { id },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
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
          include: {
            agent: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
        _count: {
          select: {
            assignments: true,
            pointages: true,
            incidents: true,
            siteTasks: true,
            reports: true,
          },
        },
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');
    return {
      ...site,
      canRelaunch: !site.isActive || site.type === 'PERMANENCE',
    };
  }

  /**
   * Relance un site clôturé / inactif pour remise en état ou intervention permanence.
   * Le chef doit être assigné au site (sauf ADMIN).
   */
  async relaunch(
    siteId: string,
    userId: string,
    role: string,
    reason?: string,
    startDate?: string,
  ) {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        chefs: { select: { chefId: true } },
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');

    if (role === 'CHEF') {
      const isAssigned = site.chefs.some((c) => c.chefId === userId);
      if (!isAssigned) {
        throw new ForbiddenException(
          "Vous n'êtes pas assigné à ce site — relance impossible",
        );
      }
    }

    const newStart = startDate ? new Date(startDate) : new Date();

    const updated = await this.prisma.site.update({
      where: { id: siteId },
      data: {
        isActive: true,
        startDate: newStart,
        endDate: null,
      },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
      },
    });

    // Journal audit
    try {
      await this.prisma.auditLog.create({
        data: {
          userId,
          action: 'SITE_RELAUNCH',
          entity: 'Site',
          entityId: siteId,
          metadata: {
            reason: reason || 'Remise en état / intervention',
            previousActive: site.isActive,
            type: site.type,
            name: site.name,
          } as Prisma.InputJsonValue,
        },
      });
    } catch {
      // ignore
    }

    return {
      ...updated,
      relaunched: true,
      message:
        site.type === 'PERMANENCE'
          ? 'Permanence relancée — vous pouvez composer l\'équipe'
          : 'Chantier relancé pour remise en état — composez votre équipe',
    };
  }

  /** Historique chronologique des activités d'un site. */
  async getActivityHistory(siteId: string) {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      select: {
        id: true,
        name: true,
        type: true,
        isActive: true,
        startDate: true,
        endDate: true,
        address: true,
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');

    const [assignments, pointages, incidents, tasks, reports, fiches] =
      await Promise.all([
        this.prisma.assignment.findMany({
          where: { siteId },
          orderBy: { createdAt: 'desc' },
          take: 80,
          include: {
            agent: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
        }),
        this.prisma.pointage.findMany({
          where: { siteId },
          orderBy: { notedAt: 'desc' },
          take: 80,
          include: {
            agent: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
        }),
        this.prisma.incident.findMany({
          where: { siteId },
          orderBy: { createdAt: 'desc' },
          take: 40,
        }),
        this.prisma.siteTask.findMany({
          where: { siteId },
          orderBy: { performedAt: 'desc' },
          take: 40,
        }),
        this.prisma.siteReport.findMany({
          where: { siteId },
          orderBy: { closedAt: 'desc' },
          take: 20,
        }),
        this.prisma.materialFiche.findMany({
          where: { siteId },
          orderBy: { createdAt: 'desc' },
          take: 30,
        }),
      ]);

    type Item = {
      kind: string;
      title: string;
      subtitle?: string;
      status?: string;
      at: string;
      meta?: Record<string, unknown>;
    };

    const items: Item[] = [];

    for (const a of assignments) {
      const name = `${a.agent.firstName} ${a.agent.lastName}`.trim();
      items.push({
        kind: 'assignment',
        title: `Affectation — ${name}`,
        subtitle: a.status,
        status: a.status,
        at: a.createdAt.toISOString(),
        meta: {
          assignmentId: a.id,
          agentId: a.agentId,
          startDate: a.startDate,
          endDate: a.endDate,
        },
      });
    }

    for (const p of pointages) {
      const name = `${p.agent.firstName} ${p.agent.lastName}`.trim();
      items.push({
        kind: 'pointage',
        title: `Pointage ${p.type} — ${name}`,
        status: p.type,
        at: p.notedAt.toISOString(),
        meta: { pointageId: p.id, agentId: p.agentId },
      });
    }

    for (const i of incidents) {
      items.push({
        kind: 'incident',
        title: `Incident — ${i.type}`,
        subtitle: i.description?.slice(0, 120),
        status: i.status,
        at: i.createdAt.toISOString(),
        meta: { incidentId: i.id, severity: i.severity },
      });
    }

    for (const t of tasks) {
      items.push({
        kind: 'task',
        title: 'Tâche',
        subtitle: t.description?.slice(0, 120),
        at: t.performedAt.toISOString(),
        meta: { taskId: t.id },
      });
    }

    for (const r of reports) {
      items.push({
        kind: 'report',
        title: 'Rapport de fin de chantier',
        subtitle: r.summary?.slice(0, 120),
        status: r.status,
        at: r.closedAt.toISOString(),
        meta: { reportId: r.id },
      });
    }

    for (const f of fiches) {
      items.push({
        kind: 'material',
        title: `Fiche matériel ${f.code}`,
        status: f.status,
        at: f.createdAt.toISOString(),
        meta: { ficheId: f.id },
      });
    }

    items.sort((a, b) => b.at.localeCompare(a.at));

    return {
      site,
      total: items.length,
      counts: {
        assignments: assignments.length,
        pointages: pointages.length,
        incidents: incidents.length,
        tasks: tasks.length,
        reports: reports.length,
        material: fiches.length,
      },
      items: items.slice(0, 150),
    };
  }

  async assignChef(siteId: string, chefId: string) {
    const existing = await this.prisma.siteChef.findUnique({
      where: { siteId_chefId: { siteId, chefId } },
    });
    if (existing) {
      throw new ConflictException('Ce chef est déjà assigné à ce site');
    }
    return this.prisma.siteChef.create({
      data: { siteId, chefId },
      include: {
        chef: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }

  async removeChef(siteId: string, chefId: string) {
    try {
      await this.prisma.siteChef.delete({
        where: { siteId_chefId: { siteId, chefId } },
      });
      return { ok: true };
    } catch {
      throw new NotFoundException('Assignation chef introuvable');
    }
  }

  async transferSite(
    siteId: string,
    toChefId: string,
    fromUserId: string,
    fromRole: string,
    keepSelf = false,
  ) {
    const site = await this.findOne(siteId);

    const toChef = await this.prisma.user.findFirst({
      where: { id: toChefId, role: Role.CHEF, isActive: true },
    });
    if (!toChef) throw new NotFoundException('Chef destinataire introuvable');

    if (fromRole === 'CHEF') {
      const isAssigned = site.chefs.some((c) => c.chefId === fromUserId);
      if (!isAssigned) {
        throw new ForbiddenException(
          "Vous n'êtes pas assigné à ce site — transfert impossible",
        );
      }
    }

    await this.prisma.siteChef.upsert({
      where: { siteId_chefId: { siteId, chefId: toChefId } },
      create: { siteId, chefId: toChefId },
      update: {},
    });

    if (!keepSelf && fromRole === 'CHEF' && fromUserId !== toChefId) {
      try {
        await this.prisma.siteChef.delete({
          where: { siteId_chefId: { siteId, chefId: fromUserId } },
        });
      } catch {
        // déjà retiré
      }
    }

    try {
      await this.prisma.appNotification.create({
        data: {
          userId: toChefId,
          type: 'SITE_TRANSFER',
          title: 'Site reçu',
          body: `Le site « ${site.name} » vous a été confié.`,
          data: { siteId } as Prisma.InputJsonValue,
        },
      });
    } catch {
      // ignore
    }

    return this.findOne(siteId);
  }
}
