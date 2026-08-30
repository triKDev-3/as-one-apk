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
exports.AgentService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
let AgentService = class AgentService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async toggleAvailability(userId, isAvailable) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: { agentProfile: true },
        });
        if (!user || user.role !== client_1.Role.AGENT) {
            throw new common_1.ForbiddenException('Seul un agent peut modifier sa disponibilité');
        }
        const now = new Date();
        if (now.getHours() >= 22) {
            throw new common_1.BadRequestException('Les disponibilités ne sont plus modifiables après 22h');
        }
        if (!user.agentProfile) {
            await this.prisma.agentProfile.create({
                data: { userId, isAvailable },
            });
        }
        else {
            await this.prisma.agentProfile.update({
                where: { userId },
                data: {
                    isAvailable,
                    lastAvailabilityChange: now,
                },
            });
        }
        const profile = await this.prisma.agentProfile.findUnique({ where: { userId } });
        if (profile) {
            await this.prisma.availabilityLog.create({
                data: {
                    agentId: profile.id,
                    isAvailable,
                },
            });
        }
        return { isAvailable, updatedAt: now };
    }
    async getMyDashboard(userId) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: {
                agentProfile: true,
                assignments: {
                    where: {
                        status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
                    },
                    include: {
                        site: { select: { id: true, name: true, type: true, address: true } },
                    },
                    orderBy: { startDate: 'desc' },
                    take: 20,
                },
                payrollLines: {
                    orderBy: { createdAt: 'desc' },
                    take: 5,
                    include: { period: true },
                },
            },
        });
        if (!user)
            throw new common_1.NotFoundException();
        const ranking = await this.prisma.user.findMany({
            where: { role: client_1.Role.AGENT, isActive: true },
            select: { id: true, firstName: true, lastName: true, rankingScore: true },
            orderBy: { rankingScore: 'desc' },
            take: 50,
        });
        const myRank = ranking.findIndex((a) => a.id === userId) + 1;
        return {
            profile: {
                id: user.id,
                firstName: user.firstName,
                lastName: user.lastName,
                phone: user.phone,
                agentType: user.agentType,
                isAvailable: user.agentProfile?.isAvailable ?? true,
                rankingScore: user.rankingScore,
                myRank: myRank || null,
            },
            assignments: user.assignments,
            recentPayroll: user.payrollLines,
            ranking: ranking.map((a, i) => ({
                rank: i + 1,
                name: `${a.firstName} ${a.lastName}`,
                score: a.rankingScore,
                isMe: a.id === userId,
            })),
        };
    }
    async getAvailableAgents() {
        const agents = await this.prisma.user.findMany({
            where: {
                role: client_1.Role.AGENT,
                isActive: true,
            },
            select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
                rankingScore: true,
                agentProfile: { select: { isAvailable: true, lastAvailabilityChange: true } },
            },
            orderBy: [{ rankingScore: 'desc' }, { lastName: 'asc' }],
        });
        return agents.sort((a, b) => {
            const avA = a.agentProfile?.isAvailable === true ? 0 : 1;
            const avB = b.agentProfile?.isAvailable === true ? 0 : 1;
            if (avA !== avB)
                return avA - avB;
            return (b.rankingScore ?? 0) - (a.rankingScore ?? 0);
        });
    }
    async getPointagesHistory(agentId) {
        const pointages = await this.prisma.pointage.findMany({
            where: { agentId },
            include: {
                site: { select: { name: true } },
            },
            orderBy: { notedAt: 'desc' },
        });
        return pointages.map((p) => ({
            id: p.id,
            siteName: p.site.name,
            type: p.type,
            date: p.notedAt.toISOString(),
            location: p.latitude && p.longitude ? { lat: p.latitude, lng: p.longitude } : null,
        }));
    }
    async getPlanning(agentId, monthKey) {
        const now = new Date();
        let startDate;
        let endDate;
        if (monthKey && /^\d{4}-\d{2}$/.test(monthKey)) {
            const [year, month] = monthKey.split('-').map(Number);
            startDate = new Date(year, month - 1, 1);
            endDate = new Date(year, month, 0, 23, 59, 59);
        }
        else {
            startDate = new Date(now.getFullYear(), now.getMonth() - 2, 1);
            endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
        }
        const pointages = await this.prisma.pointage.findMany({
            where: {
                agentId,
                notedAt: { gte: startDate, lte: endDate },
                type: 'ARRIVEE'
            },
            include: { site: { select: { name: true } } },
            orderBy: { notedAt: 'asc' },
        });
        const routines = await this.prisma.assignment.findMany({
            where: {
                agentId,
                status: { in: ['CONFIRMED', 'PENDING_CONFIRMATION', 'LOCKED'] },
                missionType: 'ROUTINE'
            },
            include: { site: { select: { name: true } } }
        });
        const profile = await this.prisma.agentProfile.findUnique({ where: { userId: agentId } });
        const unavailableDates = profile?.unavailableDates ?? [];
        const calendarMap = {};
        for (const routine of routines) {
            const days = routine.routineDays;
            if (!Array.isArray(days) || days.length === 0)
                continue;
            let current = new Date(startDate);
            while (current <= endDate) {
                const dayOfWeek = current.getDay() === 0 ? 7 : current.getDay();
                if (days.includes(dayOfWeek)) {
                    const rStart = new Date(routine.startDate);
                    rStart.setHours(0, 0, 0, 0);
                    let rEnd = routine.endDate ? new Date(routine.endDate) : null;
                    if (rEnd)
                        rEnd.setHours(23, 59, 59, 999);
                    if (current >= rStart && (!rEnd || current <= rEnd)) {
                        const dateKey = current.toISOString().split('T')[0];
                        calendarMap[dateKey] = { status: 'routine', siteName: routine.site.name };
                    }
                }
                current.setDate(current.getDate() + 1);
            }
        }
        for (const p of pointages) {
            const dateKey = p.notedAt.toISOString().split('T')[0];
            calendarMap[dateKey] = { status: 'worked', siteName: p.site.name };
        }
        for (const d of unavailableDates) {
            if (!calendarMap[d]) {
                calendarMap[d] = { status: 'unavailable' };
            }
        }
        return calendarMap;
    }
    async getRemuneration(agentId) {
        const user = await this.prisma.user.findUnique({
            where: { id: agentId },
            include: { agentProfile: true },
        });
        if (!user)
            throw new common_1.NotFoundException('Agent non trouvé');
        const pointages = await this.prisma.pointage.findMany({
            where: { agentId, type: 'ARRIVEE' },
            orderBy: { notedAt: 'desc' },
            include: { site: true },
        });
        const monthlyData = {};
        for (const p of pointages) {
            const monthKey = p.notedAt.toISOString().substring(0, 7);
            if (!monthlyData[monthKey]) {
                monthlyData[monthKey] = { daysWorked: 0, totalAmount: 0, details: [] };
            }
            const rate = p.site.dailyRate ? Number(p.site.dailyRate) : (user.agentType === 'PERMANENT' ? 5000 : 3000);
            monthlyData[monthKey].daysWorked += 1;
            monthlyData[monthKey].totalAmount += rate;
            monthlyData[monthKey].details.push({
                date: p.notedAt,
                siteName: p.site.name,
                amount: rate,
            });
        }
        const paidMonths = user.agentProfile?.paidMonths || {};
        const result = Object.entries(monthlyData).map(([monthKey, data]) => ({
            monthKey,
            daysWorked: data.daysWorked,
            totalAmount: data.totalAmount,
            isPaid: !!paidMonths[monthKey],
            paidAt: paidMonths[monthKey] || null,
            details: data.details,
        }));
        return result.sort((a, b) => b.monthKey.localeCompare(a.monthKey));
    }
    async markMonthPaid(agentId, monthKey) {
        const profile = await this.prisma.agentProfile.findUnique({
            where: { userId: agentId },
        });
        if (!profile)
            throw new common_1.NotFoundException('Profil agent non trouvé');
        const paidMonths = (profile.paidMonths || {});
        paidMonths[monthKey] = new Date().toISOString();
        await this.prisma.agentProfile.update({
            where: { userId: agentId },
            data: { paidMonths },
        });
        return { success: true, monthKey, paidAt: paidMonths[monthKey] };
    }
    async markDayAvailability(userId, date, available) {
        if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
            throw new common_1.BadRequestException('Format de date invalide (YYYY-MM-DD attendu)');
        }
        const profile = await this.prisma.agentProfile.findUnique({
            where: { userId },
        });
        if (!profile) {
            throw new common_1.NotFoundException('Profil agent non trouvé');
        }
        let unavailableDates = profile.unavailableDates || [];
        if (available) {
            unavailableDates = unavailableDates.filter((d) => d !== date);
        }
        else {
            if (!unavailableDates.includes(date)) {
                unavailableDates.push(date);
            }
        }
        await this.prisma.agentProfile.update({
            where: { userId },
            data: {
                unavailableDates,
            },
        });
        return { success: true, date, available };
    }
};
exports.AgentService = AgentService;
exports.AgentService = AgentService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AgentService);
//# sourceMappingURL=agent.service.js.map