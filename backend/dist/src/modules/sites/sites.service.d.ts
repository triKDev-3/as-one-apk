import { PrismaService } from '../../prisma/prisma.service';
import { CreateSiteDto } from './dto/create-site.dto';
export declare class SitesService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateSiteDto, createdById: string): Promise<{
        id: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        type: import(".prisma/client").$Enums.SiteType;
        address: string | null;
        location: string | null;
        startDate: Date | null;
        endDate: Date | null;
        dailyRate: import("@prisma/client/runtime/library").Decimal | null;
        exceptionalRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        createdById: string | null;
    }>;
    findAll(type?: string): Promise<({
        chefs: ({
            chef: {
                id: string;
                firstName: string;
                lastName: string;
            };
        } & {
            id: string;
            siteId: string;
            chefId: string;
        })[];
    } & {
        id: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        type: import(".prisma/client").$Enums.SiteType;
        address: string | null;
        location: string | null;
        startDate: Date | null;
        endDate: Date | null;
        dailyRate: import("@prisma/client/runtime/library").Decimal | null;
        exceptionalRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        createdById: string | null;
    })[]>;
    findOne(id: string): Promise<{
        assignments: ({
            agent: {
                id: string;
                phone: string;
                firstName: string;
                lastName: string;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            startDate: Date;
            endDate: Date | null;
            createdById: string;
            siteId: string;
            agentId: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            isLocked: boolean;
            confirmedAt: Date | null;
            refusedAt: Date | null;
        })[];
    } & {
        id: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        name: string;
        type: import(".prisma/client").$Enums.SiteType;
        address: string | null;
        location: string | null;
        startDate: Date | null;
        endDate: Date | null;
        dailyRate: import("@prisma/client/runtime/library").Decimal | null;
        exceptionalRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        createdById: string | null;
    }>;
    assignChef(siteId: string, chefId: string): Promise<{
        id: string;
        siteId: string;
        chefId: string;
    }>;
}
