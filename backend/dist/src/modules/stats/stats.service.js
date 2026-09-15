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
exports.StatsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
let StatsService = class StatsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getLiveStats(userId, role, all) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const isFiltered = role === 'CHEF' && !all;
        const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};
        const [totalAgents, availableAgents, totalChefs, activeSites, todayPointages, openIncidents, pendingAssignments,] = await Promise.all([
            this.prisma.user.count({ where: { role: 'AGENT', isActive: true } }),
            this.prisma.agentProfile.count({
                where: { isAvailable: true, user: { isActive: true } },
            }),
            this.prisma.user.count({ where: { role: 'CHEF', isActive: true } }),
            this.prisma.site.count({ where: { isActive: true, ...siteFilter } }),
            this.prisma.pointage.count({
                where: {
                    notedAt: { gte: today, lt: tomorrow },
                    ...(isFiltered ? { site: siteFilter } : {}),
                },
            }),
            this.prisma.incident.count({
                where: {
                    status: 'OUVERT',
                    ...(isFiltered ? { site: siteFilter } : {}),
                },
            }),
            this.prisma.assignment.count({
                where: {
                    status: 'PENDING_CONFIRMATION',
                    ...(isFiltered ? { site: siteFilter } : {}),
                },
            }),
        ]);
        return {
            totalAgents,
            availableAgents,
            busyAgents: totalAgents - availableAgents,
            totalChefs,
            activeSites,
            todayPointages,
            openIncidents,
            pendingAssignments,
            updatedAt: new Date().toISOString(),
        };
    }
    async enrichWithStatus(userIds) {
        if (userIds.length === 0)
            return [];
        const activeAssignments = await this.prisma.assignment.findMany({
            where: {
                agentId: { in: userIds },
                status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
            },
            include: { site: { select: { id: true, name: true } } },
        });
        const profiles = await this.prisma.agentProfile.findMany({
            where: { userId: { in: userIds } },
            select: { userId: true, isAvailable: true },
        });
        const assignmentMap = new Map();
        for (const a of activeAssignments) {
            assignmentMap.set(a.agentId, a.site?.name ?? 'Site inconnu');
        }
        const profileMap = new Map();
        for (const p of profiles) {
            profileMap.set(p.userId, p.isAvailable);
        }
        return userIds.map((id) => {
            const currentSite = assignmentMap.get(id) ?? null;
            const isAvailable = profileMap.get(id) ?? true;
            let status;
            if (currentSite)
                status = 'SUR_CHANTIER';
            else if (!isAvailable)
                status = 'INDISPONIBLE';
            else
                status = 'DISPONIBLE';
            return { userId: id, currentSite, status };
        });
    }
    async getAgentsDetails(type, userId, role, all) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const isFiltered = role === 'CHEF' && !all;
        const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};
        let rawUsers = [];
        switch (type) {
            case 'total_agents':
                rawUsers = await this.prisma.user.findMany({
                    where: { role: 'AGENT', isActive: true },
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        phone: true,
                        agentType: true,
                    },
                });
                break;
            case 'available_agents': {
                const availableProfiles = await this.prisma.agentProfile.findMany({
                    where: { isAvailable: true, user: { isActive: true } },
                    include: {
                        user: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                                agentType: true,
                            },
                        },
                    },
                });
                rawUsers = availableProfiles.map((p) => p.user);
                break;
            }
            case 'busy_agents': {
                const busyProfiles = await this.prisma.agentProfile.findMany({
                    where: { isAvailable: false, user: { isActive: true } },
                    include: {
                        user: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                                agentType: true,
                            },
                        },
                    },
                });
                rawUsers = busyProfiles.map((p) => p.user);
                break;
            }
            case 'pending_assignments': {
                const assignments = await this.prisma.assignment.findMany({
                    where: {
                        status: 'PENDING_CONFIRMATION',
                        ...(isFiltered ? { site: siteFilter } : {}),
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
                });
                const uniqueAgentIds = new Set();
                for (const a of assignments) {
                    if (!uniqueAgentIds.has(a.agent.id)) {
                        uniqueAgentIds.add(a.agent.id);
                        rawUsers.push(a.agent);
                    }
                }
                break;
            }
            case 'today_pointages': {
                const pointages = await this.prisma.pointage.findMany({
                    where: {
                        notedAt: { gte: today, lt: tomorrow },
                        ...(isFiltered ? { site: siteFilter } : {}),
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
                });
                const uniquePointageAgentIds = new Set();
                for (const p of pointages) {
                    if (!uniquePointageAgentIds.has(p.agent.id)) {
                        uniquePointageAgentIds.add(p.agent.id);
                        rawUsers.push(p.agent);
                    }
                }
                break;
            }
            default:
                return [];
        }
        const userIds = rawUsers.map((u) => u.id);
        const enriched = await this.enrichWithStatus(userIds);
        const enrichedMap = new Map(enriched.map((e) => [e.userId, e]));
        return rawUsers.map((u) => ({
            ...u,
            status: enrichedMap.get(u.id)?.status ?? 'DISPONIBLE',
            currentSite: enrichedMap.get(u.id)?.currentSite ?? null,
        }));
    }
    async getAgentsBySite(userId, role, all) {
        const isFiltered = role === 'CHEF' && !all;
        const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};
        const sites = await this.prisma.site.findMany({
            where: { isActive: true, ...siteFilter },
            include: {
                assignments: {
                    where: {
                        status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
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
                },
            },
        });
        return sites.map((site) => ({
            id: site.id,
            name: site.name,
            type: site.type,
            agentCount: site.assignments.length,
            agents: site.assignments.map((a) => ({
                ...a.agent,
                status: 'SUR_CHANTIER',
                currentSite: site.name,
            })),
        }));
    }
    async getChefCalendar(userId, role, monthKey, all, siteId) {
        const [year, month] = monthKey.split('-').map(Number);
        const start = new Date(Date.UTC(year, month - 1, 1));
        const end = new Date(Date.UTC(year, month, 0, 23, 59, 59));
        const isFiltered = role === 'CHEF' && !all && !siteId;
        const siteFilter = siteId
            ? { id: siteId }
            : isFiltered
                ? { chefs: { some: { chefId: userId } } }
                : {};
        const siteWhere = Object.keys(siteFilter).length > 0 ? { site: siteFilter } : {};
        const siteIdWhere = siteId ? { siteId } : {};
        const [pointages, incidents, assignments, tasks] = await Promise.all([
            this.prisma.pointage.findMany({
                where: {
                    notedAt: { gte: start, lte: end },
                    ...siteIdWhere,
                    ...(siteId ? {} : isFiltered ? { site: siteFilter } : {}),
                },
                include: {
                    site: { select: { id: true, name: true } },
                    agent: { select: { firstName: true, lastName: true } },
                },
                orderBy: { notedAt: 'asc' },
            }),
            this.prisma.incident.findMany({
                where: {
                    createdAt: { gte: start, lte: end },
                    ...siteIdWhere,
                    ...(siteId ? {} : isFiltered ? { site: siteFilter } : {}),
                },
                include: {
                    site: { select: { id: true, name: true } },
                },
            }),
            this.prisma.assignment.findMany({
                where: {
                    OR: [
                        { startDate: { gte: start, lte: end } },
                        {
                            startDate: { lte: end },
                            OR: [{ endDate: null }, { endDate: { gte: start } }],
                        },
                    ],
                    status: {
                        in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'],
                    },
                    ...siteIdWhere,
                    ...(siteId ? {} : isFiltered ? { site: siteFilter } : {}),
                },
                include: {
                    site: { select: { id: true, name: true } },
                    agent: { select: { firstName: true, lastName: true } },
                },
            }),
            this.prisma.siteTask.findMany({
                where: {
                    performedAt: { gte: start, lte: end },
                    ...siteIdWhere,
                    ...(siteId ? {} : isFiltered ? { site: siteFilter } : {}),
                },
                include: {
                    site: { select: { id: true, name: true } },
                    createdBy: { select: { firstName: true, lastName: true } },
                },
            }),
        ]);
        const days = {};
        const ensure = (key) => {
            if (!days[key]) {
                days[key] = {
                    pointages: 0,
                    absents: 0,
                    incidents: 0,
                    pending: 0,
                    tasks: 0,
                    events: [],
                };
            }
            return days[key];
        };
        for (const p of pointages) {
            const key = p.notedAt.toISOString().slice(0, 10);
            const b = ensure(key);
            if (p.type === 'ABSENT')
                b.absents += 1;
            else
                b.pointages += 1;
            b.events.push({
                kind: p.type === 'ABSENT' ? 'absent' : 'pointage',
                label: `${p.agent.firstName} ${p.agent.lastName} · ${p.type === 'DEPART' ? 'Présent' : p.type}`,
                siteName: p.site.name,
                siteId: p.site.id,
            });
        }
        for (const i of incidents) {
            const key = i.createdAt.toISOString().slice(0, 10);
            const b = ensure(key);
            b.incidents += 1;
            const label = (i.description || 'Incident').length > 60
                ? `${(i.description || 'Incident').slice(0, 57)}…`
                : i.description || 'Incident';
            b.events.push({
                kind: 'incident',
                label,
                siteName: i.site?.name,
                siteId: i.site?.id,
            });
        }
        for (const a of assignments) {
            const aStart = new Date(a.startDate);
            aStart.setUTCHours(0, 0, 0, 0);
            const aEnd = a.endDate ? new Date(a.endDate) : aStart;
            aEnd.setUTCHours(23, 59, 59, 999);
            const cursor = new Date(Math.max(aStart.getTime(), start.getTime()));
            const limit = new Date(Math.min(aEnd.getTime(), end.getTime()));
            while (cursor <= limit) {
                if (cursor.getUTCDay() !== 0) {
                    const key = cursor.toISOString().slice(0, 10);
                    const b = ensure(key);
                    if (a.status === 'PENDING_CONFIRMATION')
                        b.pending += 1;
                    b.events.push({
                        kind: a.status === 'PENDING_CONFIRMATION'
                            ? 'assignment_pending'
                            : 'assignment',
                        label: `${a.agent.firstName} ${a.agent.lastName}`,
                        siteName: a.site.name,
                        siteId: a.site.id,
                    });
                }
                cursor.setUTCDate(cursor.getUTCDate() + 1);
            }
        }
        for (const t of tasks) {
            const key = t.performedAt.toISOString().slice(0, 10);
            const b = ensure(key);
            b.tasks += 1;
            const desc = t.description.length > 70
                ? `${t.description.slice(0, 67)}…`
                : t.description;
            b.events.push({
                kind: 'task',
                label: desc,
                siteName: t.site.name,
                siteId: t.site.id,
            });
        }
        const summary = {};
        for (const [key, b] of Object.entries(days)) {
            summary[key] = {
                pointages: b.pointages,
                absents: b.absents,
                incidents: b.incidents,
                pending: b.pending,
                tasks: b.tasks,
                hasActivity: b.pointages +
                    b.absents +
                    b.incidents +
                    b.pending +
                    b.tasks +
                    b.events.length >
                    0,
            };
        }
        return { month: monthKey, siteId: siteId ?? null, summary, days };
    }
    async getInterventionsHistory(params) {
        const isFiltered = params.role === 'CHEF' && !params.all;
        const siteFilter = isFiltered
            ? { chefs: { some: { chefId: params.userId } } }
            : {};
        const where = {
            ...(params.siteId ? { siteId: params.siteId } : {}),
            ...(isFiltered ? { site: siteFilter } : {}),
        };
        if (params.status && params.status !== 'ALL') {
            where.status = params.status;
        }
        if (params.from || params.to) {
            const range = {};
            if (params.from)
                range.gte = new Date(`${params.from}T00:00:00.000Z`);
            if (params.to)
                range.lte = new Date(`${params.to}T23:59:59.999Z`);
            where.startDate = range;
        }
        const rows = await this.prisma.assignment.findMany({
            where,
            include: {
                site: { select: { id: true, name: true, type: true } },
                agent: {
                    select: {
                        id: true,
                        firstName: true,
                        lastName: true,
                        phone: true,
                        contractType: true,
                    },
                },
                createdBy: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
            orderBy: { startDate: 'desc' },
            take: 1000,
        });
        const items = rows.map((a) => ({
            id: a.id,
            status: a.status,
            missionType: a.missionType,
            startDate: a.startDate,
            endDate: a.endDate,
            confirmedAt: a.confirmedAt,
            refusedAt: a.refusedAt,
            isLocked: a.isLocked,
            siteId: a.site.id,
            siteName: a.site.name,
            siteType: a.site.type,
            agentId: a.agent.id,
            agentName: `${a.agent.firstName} ${a.agent.lastName}`.trim(),
            agentPhone: a.agent.phone,
            agentContract: a.agent.contractType,
            chefName: a.createdBy
                ? `${a.createdBy.firstName} ${a.createdBy.lastName}`.trim()
                : null,
            createdAt: a.createdAt,
        }));
        const byStatus = {};
        for (const it of items) {
            byStatus[it.status] = (byStatus[it.status] || 0) + 1;
        }
        return {
            count: items.length,
            byStatus,
            items,
        };
    }
};
exports.StatsService = StatsService;
exports.StatsService = StatsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], StatsService);
//# sourceMappingURL=stats.service.js.map