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
                exceptionalRate: dto.exceptionalRate,
                bonusAmount: dto.bonusAmount,
                createdById,
            },
        });
    }
    async findAll(type) {
        return this.prisma.site.findMany({
            where: {
                isActive: true,
                ...(type ? { type: type } : {}),
            },
            include: {
                chefs: {
                    include: {
                        chef: { select: { id: true, firstName: true, lastName: true } },
                    },
                },
            },
            orderBy: { name: 'asc' },
        });
    }
    async findOne(id) {
        const site = await this.prisma.site.findUnique({
            where: { id },
            include: {
                assignments: {
                    include: {
                        agent: { select: { id: true, firstName: true, lastName: true, phone: true } },
                    },
                },
            },
        });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        return site;
    }
    async assignChef(siteId, chefId) {
        return this.prisma.siteChef.create({
            data: { siteId, chefId },
        });
    }
};
exports.SitesService = SitesService;
exports.SitesService = SitesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SitesService);
//# sourceMappingURL=sites.service.js.map