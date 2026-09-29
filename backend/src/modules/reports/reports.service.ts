import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { CloseReportDto } from './dto/close-report.dto';
import { AssignmentStatus, SiteType } from '@prisma/client';
import { assertCanOperateOnSite } from '../../common/site-access';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async addTask(siteId: string, dto: CreateTaskDto, createdById: string) {
    const site = await this.prisma.site.findUnique({ where: { id: siteId } });
    if (!site) throw new NotFoundException('Site introuvable');
    await assertCanOperateOnSite(this.prisma, siteId, createdById);

    const description = (dto.description || '').trim();
    if (!description) {
      throw new BadRequestException('Veuillez d\'abord saisir la tâche.');
    }

    return this.prisma.siteTask.create({
      data: {
        siteId,
        description,
        performedAt: dto.performedAt ? new Date(dto.performedAt) : new Date(),
        createdById,
      },
      include: {
        createdBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }

  async listTasks(siteId: string) {
    return this.prisma.siteTask.findMany({
      where: { siteId },
      include: {
        createdBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: { performedAt: 'asc' },
    });
  }

  async listTasksHistory(opts: { date?: string; siteId?: string }) {
    const where: { siteId?: string; performedAt?: { gte: Date; lte: Date } } = {};
    if (opts.siteId) where.siteId = opts.siteId;
    if (opts.date && /^\d{4}-\d{2}-\d{2}$/.test(opts.date)) {
      where.performedAt = {
        gte: new Date(`${opts.date}T00:00:00.000Z`),
        lte: new Date(`${opts.date}T23:59:59.999Z`),
      };
    }
    return this.prisma.siteTask.findMany({
      where,
      include: {
        site: { select: { id: true, name: true } },
        createdBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: { performedAt: 'desc' },
      take: 500,
    });
  }

  /**
   * Rapport de fin de chantier par le chef.
   * Le site RESTE ACTIF jusqu'à décision admin (clôture ou permanence).
   */
  async closeAndGenerateReport(
    siteId: string,
    dto: CloseReportDto,
    createdById: string,
  ) {
    const site = await this.prisma.site.findUnique({
      where: { id: siteId },
      include: {
        chefs: {
          include: {
            chef: {
              select: { id: true, firstName: true, lastName: true, phone: true },
            },
          },
        },
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');
    await assertCanOperateOnSite(this.prisma, siteId, createdById);

    const [tasks, assignments, pointages, materials, incidents] =
      await Promise.all([
        this.prisma.siteTask.findMany({
          where: { siteId },
          orderBy: { performedAt: 'asc' },
          include: {
            createdBy: {
              select: { firstName: true, lastName: true },
            },
          },
        }),
        this.prisma.assignment.findMany({
          where: {
            siteId,
            status: {
              in: [
                AssignmentStatus.CONFIRMED,
                AssignmentStatus.LOCKED,
                AssignmentStatus.COMPLETED,
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
                agentType: true,
              },
            },
          },
        }),
        this.prisma.pointage.findMany({
          where: { siteId },
          orderBy: { notedAt: 'asc' },
          include: {
            agent: {
              select: { firstName: true, lastName: true },
            },
          },
        }),
        this.prisma.materialMovement.findMany({
          where: { siteId },
          include: {
            item: true,
            retention: true,
          },
          orderBy: { createdAt: 'asc' },
        }),
        this.prisma.incident.findMany({
          where: { siteId },
          orderBy: { createdAt: 'asc' },
        }),
      ]);

    const startDate = dto.startDate
      ? new Date(dto.startDate)
      : site.startDate || site.createdAt;
    const endDate = dto.endDate ? new Date(dto.endDate) : new Date();

    const details = {
      site: {
        id: site.id,
        name: site.name,
        type: site.type,
        address: site.address,
        location: site.location,
        dailyRate: site.dailyRate,
        nightRate: site.nightRate,
        sundayRate: site.sundayRate,
        bonusAmount: site.bonusAmount,
        monthlySalary: site.monthlySalary,
        fixedAmount: site.fixedAmount,
      },
      period: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
      },
      chefs: site.chefs.map((c) => c.chef),
      team: assignments.map((a) => ({
        assignmentId: a.id,
        status: a.status,
        startDate: a.startDate,
        endDate: a.endDate,
        agent: a.agent,
      })),
      tasks: tasks.map((t) => ({
        id: t.id,
        description: t.description,
        performedAt: t.performedAt,
        by: t.createdBy
          ? `${t.createdBy.firstName} ${t.createdBy.lastName}`
          : null,
      })),
      pointages: pointages.map((p) => ({
        type: p.type,
        notedAt: p.notedAt,
        agent: p.agent
          ? `${p.agent.firstName} ${p.agent.lastName}`
          : null,
        photoUrl: p.photoUrl,
      })),
      materials: materials.map((m) => ({
        type: m.type,
        quantity: m.quantity,
        state: m.state,
        item: m.item?.name,
        unitPrice: m.item?.unitPrice,
        printableRef: m.printableRef,
        retention: m.retention,
        createdAt: m.createdAt,
      })),
      incidents: incidents.map((i) => ({
        type: i.type,
        severity: i.severity,
        description: i.description,
        status: i.status,
        createdAt: i.createdAt,
      })),
      stats: {
        tasksCount: tasks.length,
        teamSize: assignments.length,
        pointagesCount: pointages.length,
        materialsCount: materials.length,
        incidentsCount: incidents.length,
      },
      pendingAdminDecision: true,
    };

    const report = await this.prisma.siteReport.create({
      data: {
        siteId,
        startDate,
        endDate,
        summary: dto.summary || null,
        details,
        // En attente de décision Direction — site reste actif pour le chef
        status: 'PENDING_ADMIN',
        createdById,
      },
      include: {
        site: { select: { id: true, name: true, type: true, isActive: true } },
        createdBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    // NE PAS désactiver le site — l'admin clôture ou transforme en permanence
    return {
      ...report,
      message:
        'Rapport envoyé. Le site reste actif jusqu’à décision de la Direction (clôture définitive ou passage en permanence).',
    };
  }

  /**
   * Décision admin : CLOSE (inactif) ou PERMANENCE (type + actif).
   */
  async adminFinalizeSite(
    siteId: string,
    action: 'CLOSE' | 'PERMANENCE',
  ) {
    const site = await this.prisma.site.findUnique({ where: { id: siteId } });
    if (!site) throw new NotFoundException('Site introuvable');

    if (action === 'CLOSE') {
      await this.prisma.$transaction([
        this.prisma.site.update({
          where: { id: siteId },
          data: { isActive: false, endDate: new Date() },
        }),
        this.prisma.assignment.updateMany({
          where: {
            siteId,
            status: {
              in: [AssignmentStatus.CONFIRMED, AssignmentStatus.LOCKED],
            },
          },
          data: { status: AssignmentStatus.COMPLETED, isLocked: false },
        }),
        this.prisma.siteReport.updateMany({
          where: { siteId, status: 'PENDING_ADMIN' },
          data: { status: 'FINAL' },
        }),
      ]);
      return { ok: true, action: 'CLOSE', siteId };
    }

    // PERMANENCE
    await this.prisma.$transaction([
      this.prisma.site.update({
        where: { id: siteId },
        data: {
          type: SiteType.PERMANENCE,
          isActive: true,
          endDate: null,
        },
      }),
      this.prisma.siteReport.updateMany({
        where: { siteId, status: 'PENDING_ADMIN' },
        data: { status: 'FINAL' },
      }),
    ]);
    return { ok: true, action: 'PERMANENCE', siteId };
  }

  async getReport(reportId: string) {
    const report = await this.prisma.siteReport.findUnique({
      where: { id: reportId },
      include: {
        site: true,
        createdBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
    if (!report) throw new NotFoundException('Rapport introuvable');
    return report;
  }

  async listReportsBySite(siteId: string) {
    return this.prisma.siteReport.findMany({
      where: { siteId },
      orderBy: { closedAt: 'desc' },
      include: {
        createdBy: {
          select: { firstName: true, lastName: true },
        },
      },
    });
  }

  async listAllReports() {
    return this.prisma.siteReport.findMany({
      orderBy: { closedAt: 'desc' },
      take: 50,
      include: {
        site: { select: { id: true, name: true, type: true, isActive: true } },
        createdBy: {
          select: { firstName: true, lastName: true },
        },
      },
    });
  }

  async listPendingAdminReports() {
    return this.prisma.siteReport.findMany({
      where: { status: 'PENDING_ADMIN' },
      orderBy: { closedAt: 'desc' },
      include: {
        site: { select: { id: true, name: true, type: true, isActive: true } },
        createdBy: {
          select: { firstName: true, lastName: true },
        },
      },
    });
  }

  async getLatestReportBySite(siteId: string) {
    return this.prisma.siteReport.findFirst({
      where: { siteId },
      orderBy: { closedAt: 'desc' },
      include: {
        site: true,
        createdBy: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }

  async updateReportSummary(reportId: string, summary: string) {
    const report = await this.prisma.siteReport.findUnique({
      where: { id: reportId },
    });
    if (!report) throw new NotFoundException('Rapport introuvable');
    return this.prisma.siteReport.update({
      where: { id: reportId },
      data: { summary },
      include: {
        site: true,
        createdBy: { select: { id: true, firstName: true, lastName: true } },
      },
    });
  }
}
