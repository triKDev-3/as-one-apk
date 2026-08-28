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
exports.RatingService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
let RatingService = class RatingService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto, ratedById) {
        const assignment = await this.prisma.assignment.findUnique({
            where: { id: dto.assignmentId },
        });
        if (!assignment)
            throw new common_1.NotFoundException('Affectation introuvable');
        if (assignment.agentId !== dto.agentId) {
            throw new common_1.BadRequestException('Cet agent n\'est pas lié à cette affectation');
        }
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);
        const existing = await this.prisma.rating.findFirst({
            where: {
                assignmentId: dto.assignmentId,
                agentId: dto.agentId,
                createdAt: { gte: startOfDay, lte: endOfDay },
            },
        });
        if (existing) {
            throw new common_1.ConflictException('Cet agent a déjà été noté aujourd\'hui pour ce chantier');
        }
        const rating = await this.prisma.rating.create({
            data: {
                assignmentId: dto.assignmentId,
                agentId: dto.agentId,
                ratedById,
                score: dto.score,
                comment: dto.comment,
            },
            include: {
                agent: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
        await this.recomputeRanking(dto.agentId);
        return rating;
    }
    async recomputeRanking(agentId) {
        const agg = await this.prisma.rating.aggregate({
            where: { agentId },
            _avg: { score: true },
            _count: { score: true },
        });
        const avg = agg._avg.score ?? 0;
        await this.prisma.user.update({
            where: { id: agentId },
            data: { rankingScore: Math.round(avg * 100) / 100 },
        });
        return avg;
    }
    async getRanking(limit = 50, sortBy = 'score') {
        const agents = await this.prisma.user.findMany({
            where: { role: client_1.Role.AGENT, isActive: true },
            select: {
                id: true,
                firstName: true,
                lastName: true,
                rankingScore: true,
                agentType: true,
                _count: {
                    select: {
                        assignments: {
                            where: { status: 'COMPLETED' },
                        },
                    },
                },
            },
            take: limit * 2,
        });
        const enriched = agents.map((a) => ({
            id: a.id,
            firstName: a.firstName,
            lastName: a.lastName,
            rankingScore: a.rankingScore,
            agentType: a.agentType,
            daysWorked: a._count.assignments,
        }));
        if (sortBy === 'days') {
            enriched.sort((a, b) => b.daysWorked - a.daysWorked);
        }
        else {
            enriched.sort((a, b) => b.rankingScore - a.rankingScore);
        }
        return enriched.slice(0, limit);
    }
    async getByAssignment(assignmentId) {
        return this.prisma.rating.findMany({
            where: { assignmentId },
            include: {
                agent: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
    }
};
exports.RatingService = RatingService;
exports.RatingService = RatingService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], RatingService);
//# sourceMappingURL=rating.service.js.map