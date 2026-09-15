"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
const site_access_1 = require("../../common/site-access");
let ReportsService = class ReportsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async addTask(siteId, dto, createdById) {
        const site = await this.prisma.site.findUnique({ where: { id: siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, siteId, createdById);
        const description = (dto.description || '').trim();
        if (!description) {
            throw new common_1.BadRequestException('Veuillez d\'abord saisir la tâche.');
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
    async listTasks(siteId) {
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
    async listTasksHistory(opts) {
        const where = {};
        if (opts.siteId)
            where.siteId = opts.siteId;
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
    async closeAndGenerateReport(siteId, dto, createdById) {
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
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, siteId, createdById);
        const [tasks, assignments, pointages, materials, incidents] = await Promise.all([
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
                            client_1.AssignmentStatus.CONFIRMED,
                            client_1.AssignmentStatus.LOCKED,
                            client_1.AssignmentStatus.COMPLETED,
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
        };
        const report = await this.prisma.siteReport.create({
            data: {
                siteId,
                startDate,
                endDate,
                summary: dto.summary || null,
                details,
                status: 'FINAL',
                createdById,
            },
            include: {
                site: { select: { id: true, name: true, type: true } },
                createdBy: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
        await this.prisma.$transaction([
            this.prisma.site.update({
                where: { id: siteId },
                data: { isActive: false, endDate },
            }),
            this.prisma.assignment.updateMany({
                where: {
                    siteId,
                    status: {
                        in: [client_1.AssignmentStatus.CONFIRMED, client_1.AssignmentStatus.LOCKED],
                    },
                },
                data: { status: client_1.AssignmentStatus.COMPLETED, isLocked: false },
            }),
        ]);
        return report;
    }
    async getReport(reportId) {
        const report = await this.prisma.siteReport.findUnique({
            where: { id: reportId },
            include: {
                site: true,
                createdBy: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
        if (!report)
            throw new common_1.NotFoundException('Rapport introuvable');
        return report;
    }
    async listReportsBySite(siteId) {
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
                site: { select: { id: true, name: true, type: true } },
                createdBy: {
                    select: { firstName: true, lastName: true },
                },
            },
        });
    }
    async getLatestReportBySite(siteId) {
        const report = await this.prisma.siteReport.findFirst({
            where: { siteId },
            orderBy: { closedAt: 'desc' },
            include: {
                site: true,
                createdBy: { select: { id: true, firstName: true, lastName: true } },
            },
        });
        return report;
    }
    async updateReportSummary(reportId, summary) {
        const report = await this.prisma.siteReport.findUnique({
            where: { id: reportId },
        });
        if (!report)
            throw new common_1.NotFoundException('Rapport introuvable');
        return this.prisma.siteReport.update({
            where: { id: reportId },
            data: { summary },
            include: {
                site: true,
                createdBy: { select: { id: true, firstName: true, lastName: true } },
            },
        });
    }
};
exports.ReportsService = ReportsService;
exports.ReportsService = ReportsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], ReportsService);
//# sourceMappingURL=reports.service.js.map