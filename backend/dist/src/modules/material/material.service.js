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
const catalog_1 = require("./catalog");
const notifications_service_1 = require("../notifications/notifications.service");
function normalizeCategory(raw, returnRequired) {
    const v = (raw || '').toUpperCase();
    if (v === 'EQUIPEMENT' || v === 'CONSIGNABLE') {
        return { category: 'EQUIPEMENT', returnRequired: returnRequired ?? true };
    }
    return { category: 'CONSOMMABLE', returnRequired: returnRequired ?? false };
}
let MaterialService = class MaterialService {
    constructor(prisma, notify) {
        this.prisma = prisma;
        this.notify = notify;
    }
    async ensureDefaultCatalog() {
        let created = 0;
        for (const row of catalog_1.DEFAULT_MATERIAL_CATALOG) {
            const existing = await this.prisma.materialItem.findFirst({
                where: { OR: [{ refCode: row.refCode }, { name: row.name }] },
            });
            if (existing) {
                await this.prisma.materialItem.update({
                    where: { id: existing.id },
                    data: {
                        refCode: row.refCode,
                        name: row.name,
                        category: row.category,
                        returnRequired: row.returnRequired,
                        isActive: true,
                    },
                });
            }
            else {
                await this.prisma.materialItem.create({
                    data: {
                        refCode: row.refCode,
                        name: row.name,
                        category: row.category,
                        returnRequired: row.returnRequired,
                        unitPrice: 0,
                    },
                });
                created += 1;
            }
        }
        return { upserted: catalog_1.DEFAULT_MATERIAL_CATALOG.length, created };
    }
    async createItem(dto) {
        const { category, returnRequired } = normalizeCategory(dto.category, dto.returnRequired);
        return this.prisma.materialItem.create({
            data: {
                name: dto.name.trim(),
                refCode: dto.refCode?.trim().toUpperCase() || null,
                category,
                unitPrice: dto.unitPrice,
                returnRequired,
            },
        });
    }
    async updateItem(id, dto) {
        const item = await this.prisma.materialItem.findUnique({ where: { id } });
        if (!item)
            throw new common_1.NotFoundException('Article introuvable');
        const cat = dto.category
            ? normalizeCategory(dto.category, dto.returnRequired)
            : null;
        return this.prisma.materialItem.update({
            where: { id },
            data: {
                ...(dto.name ? { name: dto.name.trim() } : {}),
                ...(dto.refCode !== undefined
                    ? { refCode: dto.refCode?.trim().toUpperCase() || null }
                    : {}),
                ...(cat
                    ? { category: cat.category, returnRequired: cat.returnRequired }
                    : {}),
                ...(dto.unitPrice !== undefined ? { unitPrice: dto.unitPrice } : {}),
                ...(dto.returnRequired !== undefined && !cat
                    ? { returnRequired: dto.returnRequired }
                    : {}),
                ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
            },
        });
    }
    async listItems(category, includeInactive = false) {
        const cat = category
            ? normalizeCategory(category).category
            : undefined;
        const where = {
            ...(includeInactive ? {} : { isActive: true }),
            ...(cat ? { category: cat } : {}),
        };
        let items = await this.prisma.materialItem.findMany({
            where,
            orderBy: [{ category: 'asc' }, { refCode: 'asc' }, { name: 'asc' }],
        });
        if (items.length === 0) {
            await this.ensureDefaultCatalog();
            items = await this.prisma.materialItem.findMany({
                where,
                orderBy: [{ category: 'asc' }, { refCode: 'asc' }, { name: 'asc' }],
            });
        }
        return items.map((i) => ({
            ...i,
            unitPrice: Number(i.unitPrice),
        }));
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
            where: { siteId: dto.siteId, itemId: dto.itemId, type: 'OUT' },
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
                throw new common_1.BadRequestException('Une cible de retenue est obligatoire');
            }
            if (dto.retentionTarget === client_1.RetentionTarget.ONE_AGENT && !dto.agentId) {
                throw new common_1.BadRequestException('agentId obligatoire pour une retenue individuelle');
            }
            await this.prisma.materialRetention.create({
                data: {
                    movementId: returnMovement.id,
                    target: dto.retentionTarget,
                    agentId: dto.agentId || null,
                    amount: Number(outMovement.item.unitPrice) * dto.quantity,
                    isApplied: false,
                    reason: dto.notes || dto.state,
                },
            });
        }
        return returnMovement;
    }
    async getMovementsBySite(siteId) {
        return this.prisma.materialMovement.findMany({
            where: { siteId },
            include: { item: true, retention: true },
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
            where: { isResolved: false, nextDueDate: { lte: in7Days } },
            orderBy: { nextDueDate: 'asc' },
        });
    }
    ficheInclude() {
        return {
            site: { select: { id: true, name: true, type: true, address: true } },
            requester: { select: { id: true, firstName: true, lastName: true } },
            magasinier: { select: { id: true, firstName: true, lastName: true } },
            lines: {
                include: { item: true, retention: true },
                orderBy: [{ item: { category: 'asc' } }, { item: { refCode: 'asc' } }],
            },
        };
    }
    async nextFicheCode() {
        const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const prefix = `F-ACH-07-${day}-`;
        const last = await this.prisma.materialFiche.findFirst({
            where: { code: { startsWith: prefix } },
            orderBy: { code: 'desc' },
        });
        const seq = last ? parseInt(last.code.slice(prefix.length), 10) + 1 : 1;
        return `${prefix}${String(seq).padStart(3, '0')}`;
    }
    async createFiche(dto, userId, role) {
        const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
        if (!site)
            throw new common_1.NotFoundException('Site introuvable');
        const ids = dto.lines.map((l) => l.itemId);
        const items = await this.prisma.materialItem.findMany({
            where: { id: { in: ids }, isActive: true },
        });
        if (items.length !== ids.length) {
            throw new common_1.BadRequestException('Un ou plusieurs articles sont invalides');
        }
        const isMag = role === client_1.Role.MAGASINIER || role === client_1.Role.ADMIN;
        const code = await this.nextFicheCode();
        const fiche = await this.prisma.materialFiche.create({
            data: {
                code,
                siteId: dto.siteId,
                status: isMag ? 'DRAFT' : 'REQUESTED',
                plannedReturn: dto.plannedReturn ? new Date(dto.plannedReturn) : null,
                sector: dto.sector,
                spaceCount: dto.spaceCount,
                personCount: dto.personCount,
                dayCount: dto.dayCount ?? 1,
                requesterId: isMag ? null : userId,
                magasinierId: isMag ? userId : null,
                notes: dto.notes,
                lines: {
                    create: dto.lines.map((l) => ({
                        itemId: l.itemId,
                        qtyRequested: l.qtyRequested,
                        qtyDelivered: isMag ? l.qtyDelivered ?? l.qtyRequested : 0,
                        outNotes: l.outNotes,
                    })),
                },
            },
            include: this.ficheInclude(),
        });
        if (!isMag) {
            const magasiniers = await this.prisma.user.findMany({
                where: { role: client_1.Role.MAGASINIER, isActive: true },
                select: { id: true },
            });
            await this.notify.pushMany(magasiniers.map((m) => m.id), {
                title: 'Demande de matériel',
                body: `${fiche.requester?.firstName ?? 'Chef'} demande du matériel pour ${site.name} (${code}).`,
                type: 'material:request',
                data: { ficheId: fiche.id, siteId: site.id },
            });
        }
        return fiche;
    }
    async updateFiche(id, dto, userId) {
        const fiche = await this.prisma.materialFiche.findUnique({ where: { id } });
        if (!fiche)
            throw new common_1.NotFoundException('Fiche introuvable');
        if (fiche.status === 'CLOSED' || fiche.status === 'RETURN_IN_PROGRESS') {
            throw new common_1.BadRequestException('Cette fiche ne peut plus être réécrite');
        }
        if (dto.lines) {
            const existing = await this.prisma.materialFicheLine.findMany({
                where: { ficheId: id },
            });
            const keep = new Set(dto.lines.map((l) => l.itemId));
            await this.prisma.materialFicheLine.deleteMany({
                where: { ficheId: id, itemId: { notIn: [...keep] } },
            });
            for (const l of dto.lines) {
                const prev = existing.find((e) => e.itemId === l.itemId);
                if (prev) {
                    await this.prisma.materialFicheLine.update({
                        where: { id: prev.id },
                        data: {
                            qtyRequested: l.qtyRequested,
                            qtyDelivered: l.qtyDelivered ?? prev.qtyDelivered,
                            outNotes: l.outNotes,
                        },
                    });
                }
                else {
                    await this.prisma.materialFicheLine.create({
                        data: {
                            ficheId: id,
                            itemId: l.itemId,
                            qtyRequested: l.qtyRequested,
                            qtyDelivered: l.qtyDelivered ?? 0,
                            outNotes: l.outNotes,
                        },
                    });
                }
            }
        }
        return this.prisma.materialFiche.update({
            where: { id },
            data: {
                magasinierId: userId,
                plannedReturn: dto.plannedReturn ? new Date(dto.plannedReturn) : undefined,
                sector: dto.sector,
                spaceCount: dto.spaceCount,
                personCount: dto.personCount,
                dayCount: dto.dayCount,
                notes: dto.notes,
            },
            include: this.ficheInclude(),
        });
    }
    async deliverFiche(id, userId) {
        const fiche = await this.prisma.materialFiche.findUnique({
            where: { id },
            include: { lines: { include: { item: true } }, site: true, requester: true },
        });
        if (!fiche)
            throw new common_1.NotFoundException('Fiche introuvable');
        const lines = await this.prisma.materialFicheLine.findMany({ where: { ficheId: id } });
        for (const l of lines) {
            if (l.qtyDelivered <= 0 && l.qtyRequested > 0) {
                await this.prisma.materialFicheLine.update({
                    where: { id: l.id },
                    data: { qtyDelivered: l.qtyRequested },
                });
            }
        }
        const updated = await this.prisma.materialFiche.update({
            where: { id },
            data: {
                status: 'DELIVERED',
                deliveredAt: new Date(),
                magasinierId: userId,
            },
            include: this.ficheInclude(),
        });
        if (fiche.requesterId) {
            await this.notify.push(fiche.requesterId, {
                title: 'Matériel livré',
                body: `Fiche ${fiche.code} livrée pour ${fiche.site.name}.`,
                type: 'material:delivered',
                data: { ficheId: fiche.id },
            });
        }
        return updated;
    }
    async checkReturn(id, dto, userId) {
        const fiche = await this.prisma.materialFiche.findUnique({
            where: { id },
            include: { lines: { include: { item: true } } },
        });
        if (!fiche)
            throw new common_1.NotFoundException('Fiche introuvable');
        if (fiche.status === 'CLOSED') {
            throw new common_1.BadRequestException('Fiche déjà clôturée');
        }
        for (const row of dto.lines) {
            const line = fiche.lines.find((l) => l.id === row.lineId);
            if (!line)
                throw new common_1.BadRequestException('Ligne introuvable sur cette fiche');
            const lost = row.isLost === true || row.returnState === client_1.MaterialState.MANQUANT;
            await this.prisma.materialFicheLine.update({
                where: { id: row.lineId },
                data: {
                    qtyReturned: row.qtyReturned,
                    returnState: row.returnState ?? (lost ? client_1.MaterialState.MANQUANT : client_1.MaterialState.BON),
                    isLost: lost,
                    isChecked: row.isChecked ?? true,
                    returnNotes: row.returnNotes,
                },
            });
        }
        return this.prisma.materialFiche.update({
            where: { id },
            data: { status: 'RETURN_IN_PROGRESS', magasinierId: userId },
            include: this.ficheInclude(),
        });
    }
    async closeFiche(id, userId) {
        const fiche = await this.prisma.materialFiche.findUnique({
            where: { id },
            include: { lines: { include: { item: true } } },
        });
        if (!fiche)
            throw new common_1.NotFoundException('Fiche introuvable');
        const missingEquip = fiche.lines.filter((l) => l.item.returnRequired &&
            l.qtyDelivered > 0 &&
            !l.isChecked &&
            l.qtyReturned < l.qtyDelivered);
        if (missingEquip.length > 0) {
            throw new common_1.BadRequestException(`Vérifiez le retour des équipements : ${missingEquip.map((l) => l.item.name).join(', ')}`);
        }
        return this.prisma.materialFiche.update({
            where: { id },
            data: { status: 'CLOSED', closedAt: new Date(), magasinierId: userId },
            include: this.ficheInclude(),
        });
    }
    async getFiche(id) {
        const fiche = await this.prisma.materialFiche.findUnique({
            where: { id },
            include: this.ficheInclude(),
        });
        if (!fiche)
            throw new common_1.NotFoundException('Fiche introuvable');
        return fiche;
    }
    async listFiches(opts) {
        let chefSiteIds;
        if (opts.role === client_1.Role.CHEF && !opts.siteId && opts.userId) {
            const links = await this.prisma.siteChef.findMany({
                where: { chefId: opts.userId },
                select: { siteId: true },
            });
            chefSiteIds = links.map((l) => l.siteId);
        }
        return this.prisma.materialFiche.findMany({
            where: {
                ...(opts.siteId ? { siteId: opts.siteId } : {}),
                ...(opts.status ? { status: opts.status } : {}),
                ...(chefSiteIds
                    ? {
                        OR: [
                            { siteId: { in: chefSiteIds } },
                            { requesterId: opts.userId },
                        ],
                    }
                    : {}),
            },
            include: this.ficheInclude(),
            orderBy: { createdAt: 'desc' },
            take: 200,
        });
    }
    async listDamages() {
        const lines = await this.prisma.materialFicheLine.findMany({
            where: {
                OR: [
                    { isLost: true },
                    { returnState: { in: [client_1.MaterialState.DEGRADE, client_1.MaterialState.MANQUANT] } },
                ],
            },
            include: {
                item: true,
                retention: true,
                fiche: {
                    include: {
                        site: { select: { id: true, name: true } },
                        requester: { select: { firstName: true, lastName: true } },
                    },
                },
            },
            orderBy: { fiche: { createdAt: 'desc' } },
        });
        return lines.map((l) => ({
            lineId: l.id,
            ficheId: l.ficheId,
            ficheCode: l.fiche.code,
            siteName: l.fiche.site.name,
            itemName: l.item.name,
            refCode: l.item.refCode,
            unitPrice: Number(l.item.unitPrice),
            qtyDelivered: l.qtyDelivered,
            qtyReturned: l.qtyReturned,
            qtyMissing: Math.max(0, l.qtyDelivered - l.qtyReturned),
            returnState: l.returnState,
            isLost: l.isLost,
            returnNotes: l.returnNotes,
            requester: l.fiche.requester
                ? `${l.fiche.requester.firstName} ${l.fiche.requester.lastName}`.trim()
                : null,
            sanction: l.retention
                ? {
                    id: l.retention.id,
                    amount: Number(l.retention.amount),
                    target: l.retention.target,
                    isApplied: l.retention.isApplied,
                    reason: l.retention.reason,
                }
                : null,
        }));
    }
    async applySanction(dto, adminId) {
        const line = await this.prisma.materialFicheLine.findUnique({
            where: { id: dto.lineId },
            include: { item: true, retention: true, fiche: { include: { site: true } } },
        });
        if (!line)
            throw new common_1.NotFoundException('Ligne introuvable');
        if (dto.target === client_1.RetentionTarget.ONE_AGENT && !dto.agentId) {
            throw new common_1.BadRequestException('Choisissez l\'agent responsable');
        }
        if (line.retention) {
            return this.prisma.materialRetention.update({
                where: { id: line.retention.id },
                data: {
                    target: dto.target,
                    agentId: dto.agentId || null,
                    amount: dto.amount,
                    reason: dto.reason,
                    isApplied: true,
                    appliedById: adminId,
                },
            });
        }
        const retention = await this.prisma.materialRetention.create({
            data: {
                ficheLineId: line.id,
                target: dto.target,
                agentId: dto.agentId || null,
                amount: dto.amount,
                reason: dto.reason || `${line.item.name} — ${line.returnState || 'dommage'}`,
                isApplied: true,
                appliedById: adminId,
            },
        });
        const siteName = line.fiche.site.name;
        if (dto.agentId) {
            await this.notify.push(dto.agentId, {
                title: 'Retenue matériel',
                body: `Retenue de ${dto.amount} F sur ${line.item.name} (${siteName}).`,
                type: 'material:sanction',
                data: { lineId: line.id, amount: dto.amount },
            });
        }
        return retention;
    }
};
exports.MaterialService = MaterialService;
exports.MaterialService = MaterialService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notifications_service_1.NotificationsService])
], MaterialService);
//# sourceMappingURL=material.service.js.map