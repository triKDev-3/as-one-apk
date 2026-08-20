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
exports.IncidentsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const notifications_gateway_1 = require("../notifications/notifications.gateway");
const client_1 = require("@prisma/client");
let IncidentsService = class IncidentsService {
    constructor(prisma, notifications) {
        this.prisma = prisma;
        this.notifications = notifications;
    }
    async create(dto, reportedById) {
        const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        const incident = await this.prisma.incident.create({
            data: {
                siteId: dto.siteId,
                reportedById,
                description: dto.description,
                photoUrl: dto.photoUrl,
                type: dto.type || 'AUTRE',
                severity: dto.severity || 'MOYENNE',
            },
            include: {
                site: { select: { id: true, name: true } },
                reportedBy: {
                    select: { id: true, firstName: true, lastName: true, role: true },
                },
            },
        });
        const admins = await this.prisma.user.findMany({
            where: { role: client_1.Role.ADMIN, isActive: true },
            select: { id: true },
        });
        for (const admin of admins) {
            this.notifications.notifyUser(admin.id, 'incident:new', {
                id: incident.id,
                site: incident.site,
                type: incident.type,
                severity: incident.severity,
                message: `Incident signalé sur ${incident.site.name}`,
            });
        }
        return incident;
    }
    async list(filters) {
        return this.prisma.incident.findMany({
            where: {
                ...(filters?.siteId ? { siteId: filters.siteId } : {}),
                ...(filters?.status ? { status: filters.status } : {}),
            },
            include: {
                site: { select: { id: true, name: true, type: true } },
                reportedBy: {
                    select: { id: true, firstName: true, lastName: true, role: true },
                },
            },
            orderBy: { createdAt: 'desc' },
            take: 100,
        });
    }
    async resolve(id, userId, role) {
        if (role !== client_1.Role.ADMIN && role !== client_1.Role.CHEF) {
            throw new common_1.ForbiddenException();
        }
        const incident = await this.prisma.incident.findUnique({ where: { id } });
        if (!incident)
            throw new common_1.NotFoundException();
        return this.prisma.incident.update({
            where: { id },
            data: { status: 'RESOLU', resolvedAt: new Date() },
        });
    }
};
exports.IncidentsService = IncidentsService;
exports.IncidentsService = IncidentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notifications_gateway_1.NotificationsGateway])
], IncidentsService);
//# sourceMappingURL=incidents.service.js.map