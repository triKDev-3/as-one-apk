import { PrismaService } from '../../prisma/prisma.service';
import { CreateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
export declare class MaterialService {
    private readonly prisma;
    constructor(prisma: PrismaService);
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
    materialOut(dto: MaterialOutDto, magasinierId: string): Promise<{
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
    materialReturn(dto: MaterialReturnDto, magasinierId: string): Promise<{
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
    getMovementsBySite(siteId: string): Promise<({
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
    createVehicleAlert(data: {
        vehicleName: string;
        alertType: string;
        lastDate: string;
        validityDays: number;
    }): Promise<{
        id: string;
        createdAt: Date;
        vehicleName: string;
        alertType: string;
        lastDate: Date;
        validityDays: number;
        nextDueDate: Date;
        isResolved: boolean;
    }>;
    getActiveAlerts(): Promise<{
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
