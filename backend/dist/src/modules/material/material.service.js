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
exports.MaterialService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
const crypto_1 = require("crypto");
let MaterialService = class MaterialService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createItem(dto) {
        return this.prisma.materialItem.create({
            data: {
                name: dto.name,
                category: dto.category,
                unitPrice: dto.unitPrice,
            },
        });
    }
    async listItems(category) {
        return this.prisma.materialItem.findMany({
            where: {
                isActive: true,
                ...(category ? { category } : {}),
            },
            orderBy: { name: 'asc' },
        });
    }
    async materialOut(dto, magasinierId) {
        const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        const item = await this.prisma.materialItem.findUnique({ where: { id: dto.itemId } });
        if (!item)
            throw new common_1.NotFoundException('Article introuvable');
        const printableRef = `MAT-${Date.now().toString(36).toUpperCase()}-${(0, crypto_1.randomBytes)(2).toString('hex').toUpperCase()}`;
        return this.prisma.materialMovement.create({
            data: {
                siteId: dto.siteId,
                itemId: dto.itemId,
                quantity: dto.quantity,
                type: 'OUT',
                notes: dto.notes,
                createdById: magasinierId,
                printableRef,
            },
            include: {
                item: true,
                site: { select: { id: true, name: true } },
            },
        });
    }
    async materialReturn(dto, magasinierId) {
        const outMovement = await this.prisma.materialMovement.findFirst({
            where: {
                siteId: dto.siteId,
                itemId: dto.itemId,
                type: 'OUT',
            },
            include: { item: true },
            orderBy: { createdAt: 'desc' },
        });
        if (!outMovement) {
            throw new common_1.BadRequestException('Aucune sortie trouvée pour cet article sur ce site');
        }
        const returnMovement = await this.prisma.materialMovement.create({
            data: {
                siteId: dto.siteId,
                itemId: dto.itemId,
                quantity: dto.quantity,
                type: 'RETURN',
                state: dto.state,
                notes: dto.notes,
                createdById: magasinierId,
                printableRef: outMovement.printableRef,
            },
            include: { item: true },
        });
        if (dto.state === client_1.MaterialState.DEGRADE || dto.state === client_1.MaterialState.MANQUANT) {
            if (!dto.retentionTarget) {
                throw new common_1.BadRequestException('Une cible de retenue est obligatoire (ONE_AGENT ou WHOLE_GROUP)');
            }
            const unitPrice = Number(outMovement.item.unitPrice);
            let amount = unitPrice * dto.quantity;
            if (dto.retentionTarget === client_1.RetentionTarget.WHOLE_GROUP) {
            }
            if (dto.retentionTarget === client_1.RetentionTarget.ONE_AGENT && !dto.agentId) {
                throw new common_1.BadRequestException('agentId obligatoire pour une retenue individuelle');
            }
            await this.prisma.materialRetention.create({
                data: {
                    movementId: returnMovement.id,
                    target: dto.retentionTarget,
                    agentId: dto.agentId || null,
                    amount,
                    isApplied: true,
                },
            });
        }
        return returnMovement;
    }
    async getMovementsBySite(siteId) {
        return this.prisma.materialMovement.findMany({
            where: { siteId },
            include: {
                item: true,
                retention: true,
            },
            orderBy: { createdAt: 'desc' },
        });
    }
    async createVehicleAlert(data) {
        const lastDate = new Date(data.lastDate);
        const nextDueDate = new Date(lastDate);
        nextDueDate.setDate(nextDueDate.getDate() + data.validityDays);
        return this.prisma.vehicleAlert.create({
            data: {
                vehicleName: data.vehicleName,
                alertType: data.alertType,
                lastDate,
                validityDays: data.validityDays,
                nextDueDate,
            },
        });
    }
    async getActiveAlerts() {
        const now = new Date();
        const in7Days = new Date();
        in7Days.setDate(in7Days.getDate() + 7);
        return this.prisma.vehicleAlert.findMany({
            where: {
                isResolved: false,
                nextDueDate: { lte: in7Days },
            },
            orderBy: { nextDueDate: 'asc' },
        });
    }
};
exports.MaterialService = MaterialService;
exports.MaterialService = MaterialService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MaterialService);
//# sourceMappingURL=material.service.js.map