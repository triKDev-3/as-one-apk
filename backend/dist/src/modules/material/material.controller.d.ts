import { MaterialService } from './material.service';
import { CreateMaterialItemDto, UpdateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
import { CreateVehicleAlertDto } from './dto/create-alert.dto';
import { ApplySanctionDto, CheckReturnDto, CreateMaterialFicheDto, UpdateMaterialFicheDto } from './dto/fiche.dto';
export declare class MaterialController {
    private readonly service;
    constructor(service: MaterialService);
    seedCatalog(): Promise<{
        upserted: number;
        created: number;
    }>;
    createItem(dto: CreateMaterialItemDto): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        name: string;
        refCode: string | null;
        category: string;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
        returnRequired: boolean;
    }>;
    updateItem(id: string, dto: UpdateMaterialItemDto): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        name: string;
        refCode: string | null;
        category: string;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
        returnRequired: boolean;
    }>;
    listItems(category?: string, all?: string): Promise<{
        unitPrice: number;
        id: string;
        isActive: boolean;
        createdAt: Date;
        name: string;
        refCode: string | null;
        category: string;
        returnRequired: boolean;
    }[]>;
    createFiche(dto: CreateMaterialFicheDto, req: any): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    listFiches(siteId?: string, status?: string, req?: any): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    })[]>;
    getFiche(id: string): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    updateFiche(id: string, dto: UpdateMaterialFicheDto, req: any): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    deliver(id: string, req: any): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    checkReturn(id: string, dto: CheckReturnDto, req: any): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    close(id: string, req: any): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
            address: string | null;
        };
        lines: ({
            item: {
                id: string;
                isActive: boolean;
                createdAt: Date;
                name: string;
                refCode: string | null;
                category: string;
                unitPrice: import("@prisma/client/runtime/library").Decimal;
                returnRequired: boolean;
            };
            retention: {
                id: string;
                createdAt: Date;
                agentId: string | null;
                target: import(".prisma/client").$Enums.RetentionTarget;
                amount: import("@prisma/client/runtime/library").Decimal;
                reason: string | null;
                isApplied: boolean;
                appliedById: string | null;
                movementId: string | null;
                ficheLineId: string | null;
            } | null;
        } & {
            id: string;
            itemId: string;
            qtyRequested: number;
            qtyDelivered: number;
            outNotes: string | null;
            qtyReturned: number;
            returnState: import(".prisma/client").$Enums.MaterialState | null;
            isLost: boolean;
            isChecked: boolean;
            returnNotes: string | null;
            ficheId: string;
        })[];
        requester: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
        magasinier: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        siteId: string;
        status: string;
        notes: string | null;
        plannedReturn: Date | null;
        sector: string | null;
        spaceCount: number | null;
        personCount: number | null;
        dayCount: number | null;
        code: string;
        requestDate: Date;
        deliveredAt: Date | null;
        closedAt: Date | null;
        requesterId: string | null;
        magasinierId: string | null;
    }>;
    damages(): Promise<{
        lineId: string;
        ficheId: string;
        ficheCode: string;
        siteName: string;
        itemName: string;
        refCode: string | null;
        unitPrice: number;
        qtyDelivered: number;
        qtyReturned: number;
        qtyMissing: number;
        returnState: import(".prisma/client").$Enums.MaterialState | null;
        isLost: boolean;
        returnNotes: string | null;
        requester: string | null;
        sanction: {
            id: string;
            amount: number;
            target: import(".prisma/client").$Enums.RetentionTarget;
            isApplied: boolean;
            reason: string | null;
        } | null;
    }[]>;
    sanction(dto: ApplySanctionDto, req: any): Promise<{
        id: string;
        createdAt: Date;
        agentId: string | null;
        target: import(".prisma/client").$Enums.RetentionTarget;
        amount: import("@prisma/client/runtime/library").Decimal;
        reason: string | null;
        isApplied: boolean;
        appliedById: string | null;
        movementId: string | null;
        ficheLineId: string | null;
    }>;
    materialOut(dto: MaterialOutDto, req: any): Promise<{
        site: {
            id: string;
            name: string;
        };
        item: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            name: string;
            refCode: string | null;
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            returnRequired: boolean;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        state: import(".prisma/client").$Enums.MaterialState | null;
        itemId: string;
        quantity: number;
        notes: string | null;
        printableRef: string | null;
    }>;
    materialReturn(dto: MaterialReturnDto, req: any): Promise<{
        item: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            name: string;
            refCode: string | null;
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            returnRequired: boolean;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        state: import(".prisma/client").$Enums.MaterialState | null;
        itemId: string;
        quantity: number;
        notes: string | null;
        printableRef: string | null;
    }>;
    getBySite(siteId: string): Promise<({
        item: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            name: string;
            refCode: string | null;
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            returnRequired: boolean;
        };
        retention: {
            id: string;
            createdAt: Date;
            agentId: string | null;
            target: import(".prisma/client").$Enums.RetentionTarget;
            amount: import("@prisma/client/runtime/library").Decimal;
            reason: string | null;
            isApplied: boolean;
            appliedById: string | null;
            movementId: string | null;
            ficheLineId: string | null;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        state: import(".prisma/client").$Enums.MaterialState | null;
        itemId: string;
        quantity: number;
        notes: string | null;
        printableRef: string | null;
    })[]>;
    createAlert(body: CreateVehicleAlertDto): Promise<{
        id: string;
        createdAt: Date;
        vehicleName: string;
        alertType: string;
        lastDate: Date;
        validityDays: number;
        nextDueDate: Date;
        isResolved: boolean;
    }>;
    getAlerts(): Promise<{
        id: string;
        createdAt: Date;
        vehicleName: string;
        alertType: string;
        lastDate: Date;
        validityDays: number;
        nextDueDate: Date;
        isResolved: boolean;
    }[]>;
}
