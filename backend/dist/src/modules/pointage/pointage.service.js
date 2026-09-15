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
exports.PointageService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
const notifications_gateway_1 = require("../notifications/notifications.gateway");
const notifications_service_1 = require("../notifications/notifications.service");
const site_access_1 = require("../../common/site-access");
function dayBoundsTogo(date = new Date()) {
    const key = new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Africa/Lome',
    }).format(date);
    const start = new Date(`${key}T00:00:00.000Z`);
    const end = new Date(`${key}T23:59:59.999Z`);
    return { start, end, key };
}
let PointageService = class PointageService {
    constructor(prisma, notifications, notify) {
        this.prisma = prisma;
        this.notifications = notifications;
        this.notify = notify;
    }
    async resolveCalendarConflicts(params) {
        const { agentId, siteName, type, dateKey, assignment } = params;
        const isPresence = type === client_1.PointageType.DEPART || type === client_1.PointageType.PRESENCE_PERMANENCE;
        let autoConfirmed = false;
        let autoCancelled = false;
        let clearedUnavailability = false;
        if (assignment?.status === client_1.AssignmentStatus.PENDING_CONFIRMATION) {
            if (isPresence) {
                await this.prisma.assignment.update({
                    where: { id: assignment.id },
                    data: {
                        status: client_1.AssignmentStatus.CONFIRMED,
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
            }
            else if (type === client_1.PointageType.ABSENT) {
                await this.prisma.assignment.update({
                    where: { id: assignment.id },
                    data: {
                        status: client_1.AssignmentStatus.CANCELLED,
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
        if (isPresence) {
            const profile = await this.prisma.agentProfile.findUnique({
                where: { userId: agentId },
            });
            if (profile) {
                const unavailableDates = profile.unavailableDates || [];
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
    async create(dto, createdById) {
        const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, dto.siteId, createdById);
        const type = dto.type ?? client_1.PointageType.DEPART;
        const notedDate = dto.notedAt ? new Date(dto.notedAt) : new Date();
        const { start, end, key } = dayBoundsTogo(notedDate);
        const results = [];
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
                    reason: type === client_1.PointageType.ABSENT
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
                            client_1.AssignmentStatus.CONFIRMED,
                            client_1.AssignmentStatus.LOCKED,
                            client_1.AssignmentStatus.PENDING_CONFIRMATION,
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
            const assignmentIdForPointage = resolution.autoCancelled ? null : (assignment?.id ?? null);
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
            let message;
            if (type === client_1.PointageType.ABSENT) {
                message = `Vous avez été marqué(e) absent(e) le ${dateLabel} sur ${site.name}`;
                if (resolution.autoCancelled) {
                    message += ' — affectation en attente annulée.';
                }
            }
            else if (isPast) {
                message = `Votre départ du ${dateLabel} a été enregistré sur ${site.name}`;
                if (resolution.autoConfirmed) {
                    message += ' — affectation confirmée automatiquement.';
                }
            }
            else {
                message = `Votre départ a été enregistré sur ${site.name}`;
                if (resolution.autoConfirmed) {
                    message += ' — affectation confirmée automatiquement.';
                }
            }
            await this.notify.push(agentId, {
                title: type === client_1.PointageType.ABSENT
                    ? 'Absence enregistrée'
                    : 'Pointage enregistré',
                body: message,
                type: type === client_1.PointageType.ABSENT ? 'pointage:absent' : 'pointage:depart',
                data: {
                    siteId: dto.siteId,
                    type,
                    date: key,
                    autoConfirmed: resolution.autoConfirmed,
                    autoCancelled: resolution.autoCancelled,
                },
            });
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
    async list(filters) {
        const where = {};
        if (filters?.siteId)
            where.siteId = filters.siteId;
        if (filters?.type)
            where.type = filters.type;
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
    async getBySite(siteId, date) {
        return this.list({ siteId, date });
    }
    async getByAgent(agentId, limit = 60) {
        return this.prisma.pointage.findMany({
            where: { agentId },
            include: {
                site: { select: { id: true, name: true, type: true } },
            },
            orderBy: { notedAt: 'desc' },
            take: limit,
        });
    }
};
exports.PointageService = PointageService;
exports.PointageService = PointageService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notifications_gateway_1.NotificationsGateway,
        notifications_service_1.NotificationsService])
], PointageService);
//# sourceMappingURL=pointage.service.js.map