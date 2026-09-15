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
const notifications_service_1 = require("../notifications/notifications.service");
const whatsapp_service_1 = require("../whatsapp/whatsapp.service");
const site_access_1 = require("../../common/site-access");
function dateKey(d) {
    return d.toISOString().slice(0, 10);
}
function rangesOverlap(aStart, aEnd, bStart, bEnd) {
    const aS = new Date(aStart);
    aS.setUTCHours(0, 0, 0, 0);
    const aE = aEnd ? new Date(aEnd) : new Date(aS);
    aE.setUTCHours(23, 59, 59, 999);
    const bS = new Date(bStart);
    bS.setUTCHours(0, 0, 0, 0);
    const bE = bEnd ? new Date(bEnd) : new Date(bS);
    bE.setUTCHours(23, 59, 59, 999);
    return aS <= bE && bS <= aE;
}
let AssignmentsService = class AssignmentsService {
    constructor(prisma, notifications, notify, whatsapp) {
        this.prisma = prisma;
        this.notifications = notifications;
        this.notify = notify;
        this.whatsapp = whatsapp;
    }
    async findMultiSiteConflicts(agentId, siteId, startDate, endDate) {
        const candidates = await this.prisma.assignment.findMany({
            where: {
                agentId,
                siteId: { not: siteId },
                status: {
                    in: [
                        client_1.AssignmentStatus.PENDING_CONFIRMATION,
                        client_1.AssignmentStatus.CONFIRMED,
                        client_1.AssignmentStatus.LOCKED,
                    ],
                },
            },
            include: {
                site: { select: { id: true, name: true } },
            },
        });
        return candidates.filter((c) => rangesOverlap(c.startDate, c.endDate, startDate, endDate));
    }
    async hasDepartOnDate(agentId, day) {
        const start = new Date(`${day}T00:00:00.000Z`);
        const end = new Date(`${day}T23:59:59.999Z`);
        const count = await this.prisma.pointage.count({
            where: {
                agentId,
                type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] },
                notedAt: { gte: start, lte: end },
            },
        });
        return count > 0;
    }
    async create(dto, chefId) {
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, dto.siteId, chefId);
        const agent = await this.prisma.user.findUnique({
            where: { id: dto.agentId },
            include: { agentProfile: true },
        });
        if (!agent || agent.role !== client_1.Role.AGENT) {
            throw new common_1.NotFoundException('Agent introuvable');
        }
        const startDate = new Date(dto.startDate);
        const endDate = dto.endDate ? new Date(dto.endDate) : null;
        const startKey = dateKey(startDate);
        const conflicts = await this.findMultiSiteConflicts(dto.agentId, dto.siteId, startDate, endDate);
        if (conflicts.length > 0) {
            const names = conflicts.map((c) => c.site.name).join(', ');
            const hasDepart = await this.hasDepartOnDate(dto.agentId, startKey);
            if (dto.forceMultiSite && hasDepart) {
            }
            else if (dto.forceMultiSite && !hasDepart) {
                throw new common_1.BadRequestException(`Urgence multi-sites refusée : l'agent n'a pas encore de pointage DEPART le ${startKey}. ` +
                    `Conflit avec : ${names}`);
            }
            else {
                throw new common_1.ConflictException({
                    message: `Conflit multi-sites : agent déjà affecté sur ${names}`,
                    code: 'MULTI_SITE_CONFLICT',
                    conflicts: conflicts.map((c) => ({
                        assignmentId: c.id,
                        siteId: c.site.id,
                        siteName: c.site.name,
                        status: c.status,
                        startDate: c.startDate,
                        endDate: c.endDate,
                    })),
                    canForce: hasDepart,
                    forceHint: hasDepart
                        ? 'Agent déjà pointé ce jour — vous pouvez forcer (urgence multi-chantiers).'
                        : 'Impossible de forcer tant que l\'agent n\'a pas de pointage DEPART ce jour-là (ou libérez-le d\'abord).',
                });
            }
        }
        const existingLocked = await this.prisma.assignment.findFirst({
            where: {
                agentId: dto.agentId,
                isLocked: true,
                siteId: { not: dto.siteId },
                status: { in: [client_1.AssignmentStatus.CONFIRMED, client_1.AssignmentStatus.LOCKED] },
            },
            include: { site: { select: { name: true } } },
        });
        if (existingLocked && !dto.forceMultiSite) {
            const overlaps = rangesOverlap(existingLocked.startDate, existingLocked.endDate, startDate, endDate);
            if (overlaps) {
                throw new common_1.ConflictException(`Cet agent est déjà verrouillé sur ${existingLocked.site.name}`);
            }
        }
        const unavailableDates = agent.agentProfile?.unavailableDates || [];
        const dayUnavailable = unavailableDates.includes(startKey);
        const assignment = (await this.prisma.assignment.create({
            data: {
                siteId: dto.siteId,
                agentId: dto.agentId,
                createdById: chefId,
                startDate,
                endDate,
                status: client_1.AssignmentStatus.PENDING_CONFIRMATION,
                isLocked: true,
                missionType: dto.missionType || 'TEMPORAIRE',
                routineDays: dto.routineDays
                    ? dto.routineDays
                    : client_1.Prisma.JsonNull,
                fixedSalary: dto.fixedSalary || null,
            },
            include: {
                agent: {
                    select: { id: true, firstName: true, lastName: true, phone: true },
                },
                site: { select: { id: true, name: true, type: true } },
            },
        }));
        const siteName = assignment.site?.name || 'chantier';
        let body = dayUnavailable
            ? `Affectation sur ${siteName} un jour que vous aviez marqué indisponible — confirmez avant 22h`
            : `Nouvelle affectation sur ${siteName} — confirmez avant 22h`;
        if (dto.forceMultiSite && conflicts.length > 0) {
            body += ` (urgence multi-sites — aussi sur ${conflicts.map((c) => c.site.name).join(', ')})`;
        }
        await this.notify.push(dto.agentId, {
            title: 'Nouvelle affectation',
            body,
            type: 'assignment:new',
            data: {
                id: assignment.id,
                siteId: dto.siteId,
                dayUnavailable,
                multiSite: !!dto.forceMultiSite && conflicts.length > 0,
            },
        });
        this.notifications.notifyAssignment(dto.agentId, {
            id: assignment.id,
            site: assignment.site,
            startDate: assignment.startDate,
            endDate: assignment.endDate,
            status: assignment.status,
            message: body,
        });
        if (assignment.agent?.phone) {
            const date = assignment.startDate
                ? new Date(assignment.startDate).toLocaleDateString('fr-FR')
                : 'prochainement';
            const msg = `📋 *Convocation AS ONE*\n` +
                `Bonjour ${assignment.agent.firstName} ${assignment.agent.lastName},\n` +
                `Vous êtes convoqué(e) sur le chantier *${siteName}* à partir du *${date}*.\n` +
                `Veuillez confirmer votre présence dans l'application.`;
            this.whatsapp
                .sendMessage(chefId, assignment.agent.phone, msg)
                .catch(() => { });
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
        const hourTogo = Number(new Intl.DateTimeFormat('en-GB', {
            timeZone: 'Africa/Lome',
            hour: 'numeric',
            hour12: false,
        }).format(new Date()));
        if ((hourTogo === 24 ? 0 : hourTogo) >= 22) {
            throw new common_1.BadRequestException('Il est trop tard pour confirmer ou refuser (après 22h)');
        }
        if (accept) {
            const conflicts = await this.findMultiSiteConflicts(agentId, assignment.siteId, assignment.startDate, assignment.endDate);
            for (const c of conflicts) {
                if (c.createdById) {
                    await this.notify.push(c.createdById, {
                        title: 'Agent multi-sites',
                        body: `Un agent confirmé aussi sur un autre chantier (chevauchement de dates).`,
                        type: 'assignment:multi_site',
                        data: {
                            agentId,
                            otherAssignmentId: assignmentId,
                            siteId: assignment.siteId,
                        },
                    });
                }
            }
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
                : 'Un agent';
            await this.notify.push(assignment.createdById, {
                title: accept ? 'Affectation confirmée' : 'Affectation refusée',
                body: accept
                    ? `${agentName} a confirmé l'affectation`
                    : `${agentName} a refusé l'affectation`,
                type: 'assignment:response',
                data: { assignmentId, accepted: accept },
            });
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
                status: {
                    in: [
                        client_1.AssignmentStatus.CONFIRMED,
                        client_1.AssignmentStatus.LOCKED,
                        client_1.AssignmentStatus.PENDING_CONFIRMATION,
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
                        rankingScore: true,
                        agentProfile: {
                            select: { isAvailable: true, unavailableDates: true },
                        },
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
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, assignment.siteId, fromChefId);
        const tr = await this.prisma.transferRequest.create({
            data: { assignmentId, fromChefId, toChefId },
        });
        await this.notify.push(toChefId, {
            title: 'Demande de transfert',
            body: "Un chef demande le transfert d'un agent vers vous",
            type: 'transfer:request',
            data: { transferId: tr.id, assignmentId },
        });
        return tr;
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
                        agent: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                            },
                        },
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
            await this.prisma.$transaction([
                this.prisma.transferRequest.update({
                    where: { id: transferId },
                    data: { status: 'ACCEPTED', resolvedAt: new Date() },
                }),
                this.prisma.assignment.update({
                    where: { id: tr.assignmentId },
                    data: { createdById: chefId },
                }),
                this.prisma.siteChef.upsert({
                    where: {
                        siteId_chefId: { siteId: tr.assignment.siteId, chefId },
                    },
                    create: { siteId: tr.assignment.siteId, chefId },
                    update: {},
                }),
            ]);
            await this.notify.push(tr.fromChefId, {
                title: 'Transfert accepté',
                body: 'Votre demande de transfert a été acceptée',
                type: 'transfer:accepted',
                data: { transferId },
            });
            return { ok: true, status: 'ACCEPTED' };
        }
        await this.prisma.transferRequest.update({
            where: { id: transferId },
            data: { status: 'REJECTED', resolvedAt: new Date() },
        });
        await this.notify.push(tr.fromChefId, {
            title: 'Transfert refusé',
            body: 'Votre demande de transfert a été refusée',
            type: 'transfer:rejected',
            data: { transferId },
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
        const todayStr = new Date().toISOString().slice(0, 10);
        const agents = await this.prisma.user.findMany({
            where: { role: client_1.Role.AGENT, isActive: true },
            include: {
                agentProfile: {
                    select: { isAvailable: true, unavailableDates: true },
                },
                ratingsReceived: { select: { score: true } },
                pointages: {
                    where: { type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] } },
                    select: { notedAt: true },
                },
                assignments: {
                    where: {
                        status: {
                            in: [
                                client_1.AssignmentStatus.PENDING_CONFIRMATION,
                                client_1.AssignmentStatus.CONFIRMED,
                                client_1.AssignmentStatus.LOCKED,
                            ],
                        },
                    },
                    select: {
                        id: true,
                        siteId: true,
                        startDate: true,
                        endDate: true,
                        isLocked: true,
                        status: true,
                        site: { select: { id: true, name: true } },
                    },
                },
            },
        });
        return agents.map((a) => {
            const ratings = a.ratingsReceived;
            const avgScore = ratings.length > 0
                ? ratings.reduce((sum, r) => sum + r.score, 0) / ratings.length
                : null;
            const daysWorked = new Set(a.pointages.map((p) => p.notedAt.toISOString().slice(0, 10))).size;
            const hasPointedToday = a.pointages.some((p) => p.notedAt.toISOString().slice(0, 10) === todayStr);
            const otherSites = a.assignments.filter((asgn) => {
                if (siteId && asgn.siteId === siteId)
                    return false;
                return rangesOverlap(asgn.startDate, asgn.endDate, new Date(`${todayStr}T00:00:00.000Z`), new Date(`${todayStr}T23:59:59.999Z`));
            });
            const isLockedElsewhere = otherSites.length > 0 && !hasPointedToday;
            const canForceMultiSite = otherSites.length > 0 && hasPointedToday;
            const unavailableDates = a.agentProfile?.unavailableDates || [];
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
                canForceMultiSite,
                lockedOnSites: otherSites.map((s) => ({
                    siteId: s.site.id,
                    siteName: s.site.name,
                    status: s.status,
                })),
                unavailableDates,
                isUnavailableToday: unavailableDates.includes(todayStr),
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
        await (0, site_access_1.assertCanOperateOnSite)(this.prisma, assignment.siteId, chefId);
        const updated = await this.prisma.assignment.update({
            where: { id: assignmentId },
            data: { isLocked: false, status: client_1.AssignmentStatus.CANCELLED },
        });
        const siteName = assignment.site?.name || 'chantier';
        await this.notify.push(assignment.agentId, {
            title: 'Libération de chantier',
            body: `Vous avez été libéré(e) de ${siteName}`,
            type: 'assignment:released',
            data: { assignmentId },
        });
        this.notifications.notifyAssignment(assignment.agentId, {
            id: assignmentId,
            status: updated.status,
            message: `Vous avez été libéré(e) de ${siteName}`,
        });
        if (assignment.agent?.phone) {
            const msg = `ℹ️ *AS ONE* : Vous avez été libéré(e) du chantier *${siteName}*.\n` +
                `Attendez une nouvelle convocation pour y retourner.`;
            this.whatsapp
                .sendMessage(chefId, assignment.agent.phone, msg)
                .catch(() => { });
        }
        return updated;
    }
};
exports.AssignmentsService = AssignmentsService;
exports.AssignmentsService = AssignmentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notifications_gateway_1.NotificationsGateway,
        notifications_service_1.NotificationsService,
        whatsapp_service_1.WhatsappService])
], AssignmentsService);
//# sourceMappingURL=assignments.service.js.map