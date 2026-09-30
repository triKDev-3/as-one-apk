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
import { AssignmentStatus, Role } from '@prisma/client';

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

  async findAll(type?: string, userId?: string, role?: string, all?: boolean) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter =
      isFiltered && userId ? { chefs: { some: { chefId: userId } } } : {};

    const sites = await this.prisma.site.findMany({
      where: {
        isActive: true,
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
      orderBy: { name: 'asc' },
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
          pendingAdminDecision: pendingReport != null,
          pendingReport,
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
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');
    return site;
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

  /**
   * Transfert d'un site d'un chef vers un autre.
   */
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
          'Vous n\'\u00eates pas assigné à ce site — transfert impossible',
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

    // Notif au chef destinataire (modèle Prisma = appNotification)
    try {
      await this.prisma.appNotification.create({
        data: {
          userId: toChefId,
          type: 'SITE_TRANSFER',
          title: 'Site reçu',
          body: `Le site « ${site.name} » vous a été confié.`,
          data: { siteId },
        },
      });
    } catch {
      // ignore si échec notif
    }

    return this.findOne(siteId);
  }
}
