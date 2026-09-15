import { ToggleAvailabilityDto } from './dto/toggle-availability.dto';
import { MarkDayAvailabilityDto, MarkMonthPaidDto } from './dto/mark-day.dto';
import { AgentService } from './agent.service';
export declare class AgentController {
    private readonly agentService;
    constructor(agentService: AgentService);
    toggleAvailability(req: any, dto: ToggleAvailabilityDto): Promise<{
        isAvailable: boolean;
        updatedAt: Date;
    }>;
    getMyDashboard(req: any): Promise<{
        profile: {
            id: string;
            firstName: string;
            lastName: string;
            phone: string;
            agentType: import(".prisma/client").$Enums.AgentType | null;
            isAvailable: boolean;
            rankingScore: number;
            myRank: number | null;
        };
        assignments: ({
            site: {
                id: string;
                name: string;
                type: import(".prisma/client").$Enums.SiteType;
                address: string | null;
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
            missionType: string | null;
            routineDays: import("@prisma/client/runtime/library").JsonValue | null;
            fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
            confirmedAt: Date | null;
            refusedAt: Date | null;
        })[];
        recentPayroll: ({
            period: {
                id: string;
                createdAt: Date;
                startDate: Date;
                endDate: Date;
                createdById: string;
                status: import(".prisma/client").$Enums.PayrollStatus;
                validatedAt: Date | null;
            };
        } & {
            id: string;
            createdAt: Date;
            agentId: string;
            periodId: string;
            baseAmount: import("@prisma/client/runtime/library").Decimal;
            primes: import("@prisma/client/runtime/library").Decimal;
            retenues: import("@prisma/client/runtime/library").Decimal;
            netAmount: import("@prisma/client/runtime/library").Decimal;
            details: import("@prisma/client/runtime/library").JsonValue | null;
        })[];
        ranking: {
            rank: number;
            name: string;
            score: number;
            isMe: boolean;
        }[];
    }>;
    getPointagesHistory(req: any): Promise<{
        id: string;
        siteName: string;
        type: import(".prisma/client").$Enums.PointageType;
        date: string;
        location: {
            lat: number;
            lng: number;
        } | null;
    }[]>;
    getPlanning(req: any, month?: string): Promise<{
        month: string;
        days: Record<string, {
            status: string;
            siteName?: string;
            sites?: string[];
            conflict?: boolean;
        }>;
        stats: {
            worked: number;
            absent: number;
            assigned: number;
            pending: number;
            unavailable: number;
            conflicts: number;
        };
    }>;
    getRemuneration(req: any): Promise<{
        monthKey: string;
        daysWorked: number;
        totalAmount: number;
        isPaid: boolean;
        paidAt: string | null;
        details: any[];
    }[]>;
    markMonthPaid(req: any, dto: MarkMonthPaidDto): Promise<{
        success: boolean;
        monthKey: string;
        paidAt: string;
    }>;
    getAvailable(): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
        agentType: import(".prisma/client").$Enums.AgentType | null;
        rankingScore: number;
        agentProfile: {
            isAvailable: boolean;
            lastAvailabilityChange: Date;
        } | null;
    }[]>;
    markDayAvailability(req: any, dto: MarkDayAvailabilityDto): Promise<{
        success: boolean;
        date: string;
        available: boolean;
    }>;
}
