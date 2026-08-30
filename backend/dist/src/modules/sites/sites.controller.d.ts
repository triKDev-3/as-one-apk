import { SitesService } from './sites.service';
import { CreateSiteDto } from './dto/create-site.dto';
export declare class SitesController {
    private readonly sitesService;
    constructor(sitesService: SitesService);
    create(dto: CreateSiteDto, req: any): Promise<{
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
        nightRate: import("@prisma/client/runtime/library").Decimal | null;
        sundayRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        monthlySalary: import("@prisma/client/runtime/library").Decimal | null;
        fixedAmount: import("@prisma/client/runtime/library").Decimal | null;
        createdById: string | null;
    }>;
    findAll(req: any, type?: string, all?: string): Promise<({
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
        nightRate: import("@prisma/client/runtime/library").Decimal | null;
        sundayRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        monthlySalary: import("@prisma/client/runtime/library").Decimal | null;
        fixedAmount: import("@prisma/client/runtime/library").Decimal | null;
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
            missionType: string | null;
            routineDays: import("@prisma/client/runtime/library").JsonValue | null;
            fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
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
        nightRate: import("@prisma/client/runtime/library").Decimal | null;
        sundayRate: import("@prisma/client/runtime/library").Decimal | null;
        bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
        monthlySalary: import("@prisma/client/runtime/library").Decimal | null;
        fixedAmount: import("@prisma/client/runtime/library").Decimal | null;
        createdById: string | null;
    }>;
    assignChef(siteId: string, chefId: string): Promise<{
        id: string;
        siteId: string;
        chefId: string;
    }>;
}
