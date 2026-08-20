import { MaterialService } from './material.service';
import { CreateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
export declare class MaterialController {
    private readonly service;
    constructor(service: MaterialService);
    createItem(dto: CreateMaterialItemDto): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        name: string;
        category: string;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
    }>;
    listItems(category?: string): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        name: string;
        category: string;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
    }[]>;
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
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        itemId: string;
        quantity: number;
        notes: string | null;
        state: import(".prisma/client").$Enums.MaterialState | null;
        printableRef: string | null;
    }>;
    materialReturn(dto: MaterialReturnDto, req: any): Promise<{
        item: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            name: string;
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        itemId: string;
        quantity: number;
        notes: string | null;
        state: import(".prisma/client").$Enums.MaterialState | null;
        printableRef: string | null;
    }>;
    getBySite(siteId: string): Promise<({
        item: {
            id: string;
            isActive: boolean;
            createdAt: Date;
            name: string;
            category: string;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
        };
        retention: {
            id: string;
            createdAt: Date;
            agentId: string | null;
            target: import(".prisma/client").$Enums.RetentionTarget;
            amount: import("@prisma/client/runtime/library").Decimal;
            isApplied: boolean;
            movementId: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        type: string;
        createdById: string;
        siteId: string;
        itemId: string;
        quantity: number;
        notes: string | null;
        state: import(".prisma/client").$Enums.MaterialState | null;
        printableRef: string | null;
    })[]>;
    createAlert(body: any): Promise<{
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
