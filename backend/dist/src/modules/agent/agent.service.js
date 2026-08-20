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
};
exports.AgentService = AgentService;
exports.AgentService = AgentService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AgentService);
//# sourceMappingURL=agent.service.js.map