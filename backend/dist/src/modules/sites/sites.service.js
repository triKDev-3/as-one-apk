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
exports.SitesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
let SitesService = class SitesService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto, createdById) {
        return this.prisma.site.create({
            data: {
                name: dto.name,
                type: dto.type,
                address: dto.address,
                location: dto.location,
                startDate: dto.startDate ? new Date(dto.startDate) : null,
                endDate: dto.endDate ? new Date(dto.endDate) : null,
                dailyRate: dto.dailyRate,
                nightRate: dto.nightRate ?? 4500,
                sundayRate: dto.sundayRate ?? 5000,
                bonusAmount: dto.bonusAmount,
                monthlySalary: dto.monthlySalary,
                fixedAmount: dto.fixedAmount,
                createdById,
            },
        });
    }
    async findAll(type, userId, role, all) {
        const isFiltered = role === 'CHEF' && !all;
        const siteFilter = isFiltered && userId ? { chefs: { some: { chefId: userId } } } : {};
        const sites = await this.prisma.site.findMany({
            where: {
                isActive: true,
                ...(type ? { type: type } : {}),
                ...siteFilter,
            },
            include: {
                chefs: {
                    include: {
                        chef: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                                isActive: true,
                            },
                        },
                    },
                },
                _count: {
                    select: {
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
                        },
                    },
                },
            },
            orderBy: { name: 'asc' },
        });
        const enriched = await Promise.all(sites.map(async (s) => {
            const activeAssignments = await this.prisma.assignment.findMany({
                where: {
                    siteId: s.id,
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
                    status: true,
                    startDate: true,
                    endDate: true,
                    agent: {
                        select: { id: true, firstName: true, lastName: true },
                    },
                },
                take: 50,
            });
            return {
                ...s,
                activeAgentsCount: s._count.assignments,
                activeAssignments: activeAssignments.map((a) => ({
                    id: a.id,
                    status: a.status,
                    startDate: a.startDate,
                    endDate: a.endDate,
                    agentName: `${a.agent.firstName} ${a.agent.lastName}`.trim(),
                    agentId: a.agent.id,
                })),
            };
        }));
        return enriched;
    }
    async findOne(id) {
        const site = await this.prisma.site.findUnique({
            where: { id },
            include: {
                chefs: {
                    include: {
                        chef: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                            },
                        },
                    },
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
                    include: {
                        agent: {
                            select: {
                                id: true,
                                firstName: true,
                                lastName: true,
                                phone: true,
                            },
                        },
                    },
                },
            },
        });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        return site;
    }
    async assignChef(siteId, chefId) {
        const existing = await this.prisma.siteChef.findUnique({
            where: { siteId_chefId: { siteId, chefId } },
        });
        if (existing) {
            throw new common_1.ConflictException('Ce chef est déjà assigné à ce site');
        }
        return this.prisma.siteChef.create({
            data: { siteId, chefId },
            include: {
                chef: {
                    select: { id: true, firstName: true, lastName: true },
                },
            },
        });
    }
    async removeChef(siteId, chefId) {
        try {
            await this.prisma.siteChef.delete({
                where: { siteId_chefId: { siteId, chefId } },
            });
            return { ok: true };
        }
        catch {
            throw new common_1.NotFoundException('Assignation chef introuvable');
        }
    }
};
exports.SitesService = SitesService;
exports.SitesService = SitesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SitesService);
//# sourceMappingURL=sites.service.js.map