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
exports.AssignmentsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
const notifications_gateway_1 = require("../notifications/notifications.gateway");
const whatsapp_service_1 = require("../whatsapp/whatsapp.service");
let AssignmentsService = class AssignmentsService {
    constructor(prisma, notifications, whatsapp) {
        this.prisma = prisma;
        this.notifications = notifications;
        this.whatsapp = whatsapp;
    }
    async create(dto, chefId) {
        const existingLocked = await this.prisma.assignment.findFirst({
            where: {
                agentId: dto.agentId,
                isLocked: true,
                status: { in: [client_1.AssignmentStatus.CONFIRMED, client_1.AssignmentStatus.LOCKED] },
            },
        });
        if (existingLocked) {
            throw new common_1.ConflictException('Cet agent est déjà verrouillé sur un autre chantier');
        }
        const agent = await this.prisma.user.findUnique({
            where: { id: dto.agentId },
            include: { agentProfile: true },
        });
        if (!agent || agent.role !== client_1.Role.AGENT) {
            throw new common_1.NotFoundException('Agent introuvable');
        }
        const needsConfirmation = !agent.agentProfile?.isAvailable || true;
        const assignment = await this.prisma.assignment.create({
            data: {
                siteId: dto.siteId,
                agentId: dto.agentId,
                createdById: chefId,
                startDate: new Date(dto.startDate),
                endDate: dto.endDate ? new Date(dto.endDate) : null,
                status: needsConfirmation
                    ? client_1.AssignmentStatus.PENDING_CONFIRMATION
                    : client_1.AssignmentStatus.CONFIRMED,
                isLocked: true,
            },
            include: {
                agent: { select: { id: true, firstName: true, lastName: true, phone: true } },
                site: { select: { id: true, name: true, type: true } },
            },
        });
        this.notifications.notifyAssignment(dto.agentId, {
            id: assignment.id,
            site: assignment.site,
            startDate: assignment.startDate,
            endDate: assignment.endDate,
            status: assignment.status,
            message: 'Nouvelle affectation — confirmez avant 22h',
        });
        if (assignment.agent?.phone) {
            const siteName = assignment.site?.name || 'chantier';
            const date = assignment.startDate
                ? new Date(assignment.startDate).toLocaleDateString('fr-FR')
                : 'prochainement';
            const msg = `📋 *Convocation AS ONE*\n` +
                `Bonjour ${assignment.agent.firstName} ${assignment.agent.lastName},\n` +
                `Vous êtes convoqué(e) sur le chantier *${siteName}* à partir du *${date}*.\n` +
                `Veuillez confirmer votre présence dans l'application.`;
            this.whatsapp.sendMessage(chefId, assignment.agent.phone, msg).catch(() => { });
        }
        return assignment;
    }
    async confirmOrRefuse(assignmentId, agentId, accept) {
        const assignment = await this.prisma.assignment.findUnique({
            where: { id: assignmentId },
        });
        if (!assignment || assignment.agentId !== agentId) {
            throw new common_1.ForbiddenException();
        }
        if (assignment.status !== client_1.AssignmentStatus.PENDING_CONFIRMATION) {
            throw new common_1.BadRequestException('Cette affectation ne peut plus être modifiée');
        }
        if (new Date().getHours() >= 22) {
            throw new common_1.BadRequestException('Il est trop tard pour confirmer ou refuser (après 22h)');
        }
        const updated = await this.prisma.assignment.update({
            where: { id: assignmentId },
            data: {
                status: accept ? client_1.AssignmentStatus.CONFIRMED : client_1.AssignmentStatus.REFUSED,
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
                : undefined;
            this.notifications.notifyAssignmentResponse(assignment.createdById, {
                assignmentId,
                accepted: accept,
                agentName,
            });
        }
        return updated;
    }
    async getBySite(siteId) {
        return this.prisma.assignment.findMany({
            where: {
                siteId,
                status: { in: [client_1.AssignmentStatus.CONFIRMED, client_1.AssignmentStatus.LOCKED, client_1.AssignmentStatus.PENDING_CONFIRMATION] },
            },
            include: {
                agent: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        phone: true,
                        rankingScore: true,
                    },
                },
            },
            orderBy: { createdAt: 'asc' },
        });
    }
    async requestTransfer(assignmentId, fromChefId, toChefId) {
        const assignment = await this.prisma.assignment.findUnique({
            where: { id: assignmentId },
        });
        if (!assignment || !assignment.isLocked) {
            throw new common_1.BadRequestException('Transfert impossible sur cette affectation');
        }
        return this.prisma.transferRequest.create({
            data: {
                assignmentId,
                fromChefId,
                toChefId,
            },
        });
    }
    async listPendingTransfers(chefId) {
        return this.prisma.transferRequest.findMany({
            where: {
                status: 'PENDING',
                OR: [{ toChefId: chefId }, { fromChefId: chefId }],
            },
            include: {
                assignment: {
                    include: {
                        agent: { select: { id: true, firstName: true, lastName: true, phone: true } },
                        site: { select: { id: true, name: true } },
                    },
                },
                fromChef: { select: { id: true, firstName: true, lastName: true } },
                toChef: { select: { id: true, firstName: true, lastName: true } },
            },
            orderBy: { createdAt: 'desc' },
        });
    }
    async resolveTransfer(transferId, chefId, accept) {
        const tr = await this.prisma.transferRequest.findUnique({
            where: { id: transferId },
            include: { assignment: true },
        });
        if (!tr || tr.status !== 'PENDING') {
            throw new common_1.BadRequestException('Demande de transfert invalide');
        }
        if (tr.toChefId !== chefId) {
            throw new common_1.ForbiddenException('Seul le chef destinataire peut répondre');
        }
        if (accept) {
            await this.prisma.transferRequest.update({
                where: { id: transferId },
                data: { status: 'ACCEPTED', resolvedAt: new Date() },
            });
            return { ok: true, status: 'ACCEPTED' };
        }
        await this.prisma.transferRequest.update({
            where: { id: transferId },
            data: { status: 'REJECTED', resolvedAt: new Date() },
        });
        return { ok: true, status: 'REJECTED' };
    }
    async listChefs() {
        return this.prisma.user.findMany({
            where: { role: client_1.Role.CHEF, isActive: true },
            select: { id: true, firstName: true, lastName: true, phone: true },
            orderBy: { lastName: 'asc' },
        });
    }
    async getAvailableAgents(siteId) {
        const agents = await this.prisma.user.findMany({
            where: { role: client_1.Role.AGENT, isActive: true },
            include: {
                agentProfile: { select: { isAvailable: true } },
                ratingsReceived: {
                    select: { score: true },
                },
                pointages: {
                    select: { notedAt: true },
                },
                assignments: {
                    where: {
                        isLocked: true,
                        status: { in: [client_1.AssignmentStatus.CONFIRMED, client_1.AssignmentStatus.LOCKED] },
                    },
                    select: { id: true, siteId: true },
                },
            },
        });
        return agents.map((a) => {
            const ratings = a.ratingsReceived;
            const avgScore = ratings.length > 0
                ? ratings.reduce((sum, r) => sum + r.score, 0) / ratings.length
                : null;
            const daysWorked = new Set(a.pointages.map(p => p.notedAt.toDateString())).size;
            const isLockedElsewhere = a.assignments.some((asgn) => siteId && asgn.siteId !== siteId);
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
            };
        });
    }
    async releaseAgent(assignmentId, chefId) {
        const assignment = await this.prisma.assignment.findUnique({
            where: { id: assignmentId },
            include: {
                agent: { select: { firstName: true, lastName: true, phone: true } },
                site: { select: { name: true } },
            },
        });
        if (!assignment)
            throw new common_1.NotFoundException('Affectation introuvable');
        if (assignment.createdById !== chefId)
            throw new common_1.ForbiddenException('Action non autorisée');
        const updated = await this.prisma.assignment.update({
            where: { id: assignmentId },
            data: { isLocked: false, status: client_1.AssignmentStatus.REFUSED },
        });
        this.notifications.notifyAssignment(assignment.agentId, {
            id: assignmentId,
            status: updated.status,
            message: 'Vous avez été libéré(e) de ce chantier par votre chef.',
        });
        if (assignment.agent?.phone) {
            const siteName = assignment.site?.name || 'chantier';
            const msg = `ℹ️ *AS ONE* : Vous avez été libéré(e) du chantier *${siteName}*.\n` +
                `Attendez une nouvelle convocation pour y retourner.`;
            this.whatsapp.sendMessage(chefId, assignment.agent.phone, msg).catch(() => { });
        }
        return updated;
    }
};
exports.AssignmentsService = AssignmentsService;
exports.AssignmentsService = AssignmentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notifications_gateway_1.NotificationsGateway,
        whatsapp_service_1.WhatsappService])
], AssignmentsService);
//# sourceMappingURL=assignments.service.js.map