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
let PointageService = class PointageService {
    constructor(prisma, notifications) {
        this.prisma = prisma;
        this.notifications = notifications;
    }
    async create(dto, createdById) {
        const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        const results = [];
        for (const agentId of dto.agentIds) {
            if (dto.type === client_1.PointageType.ARRIVEE || dto.type === client_1.PointageType.PRESENCE_PERMANENCE) {
                const pointageDate = dto.notedAt ? new Date(dto.notedAt) : new Date();
                const startOfDay = new Date(pointageDate);
                startOfDay.setHours(0, 0, 0, 0);
                const endOfDay = new Date(pointageDate);
                endOfDay.setHours(23, 59, 59, 999);
                const existing = await this.prisma.pointage.findFirst({
                    where: {
                        agentId,
                        siteId: dto.siteId,
                        type: dto.type,
                        notedAt: { gte: startOfDay, lte: endOfDay },
                    },
                });
                if (existing) {
                    results.push({
                        agentId,
                        status: 'skipped',
                        reason: 'Déjà pointé aujourd\'hui sur ce site',
                    });
                    continue;
                }
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
            });
            if (assignment && assignment.status === client_1.AssignmentStatus.PENDING_CONFIRMATION) {
                await this.prisma.assignment.update({
                    where: { id: assignment.id },
                    data: { status: client_1.AssignmentStatus.CONFIRMED },
                });
                assignment.status = client_1.AssignmentStatus.CONFIRMED;
            }
            const pointage = await this.prisma.pointage.create({
                data: {
                    siteId: dto.siteId,
                    agentId,
                    assignmentId: assignment?.id ?? null,
                    type: dto.type,
                    photoUrl: dto.photoUrl,
                    latitude: dto.latitude,
                    longitude: dto.longitude,
                    createdById,
                    notedAt: dto.notedAt ? new Date(dto.notedAt) : undefined,
                },
                include: {
                    agent: {
                        select: { id: true, firstName: true, lastName: true, phone: true },
                    },
                },
            });
            results.push({ agentId, status: 'ok', pointage });
            this.notifications.notifyPointage(agentId, {
                siteId: dto.siteId,
                type: dto.type,
                message: 'Votre pointage a été enregistré',
            });
        }
        return {
            siteId: dto.siteId,
            type: dto.type,
            results,
            successCount: results.filter((r) => r.status === 'ok').length,
            skippedCount: results.filter((r) => r.status === 'skipped').length,
        };
    }
    async getBySite(siteId, date) {
        const where = { siteId };
        if (date) {
            const start = new Date(date);
            start.setHours(0, 0, 0, 0);
            const end = new Date(date);
            end.setHours(23, 59, 59, 999);
            where.notedAt = { gte: start, lte: end };
        }
        return this.prisma.pointage.findMany({
            where,
            include: {
                agent: {
                    select: { id: true, firstName: true, lastName: true, phone: true },
                },
            },
            orderBy: { notedAt: 'desc' },
        });
    }
    async getByAgent(agentId, limit = 30) {
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
        notifications_gateway_1.NotificationsGateway])
], PointageService);
//# sourceMappingURL=pointage.service.js.map