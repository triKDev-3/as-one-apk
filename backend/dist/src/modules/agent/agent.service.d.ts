import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
type DayCell = {
    status: string;
    siteName?: string;
    sites?: string[];
    conflict?: boolean;
};
export declare class AgentService {
    private readonly prisma;
    private readonly notify;
    constructor(prisma: PrismaService, notify: NotificationsService);
    private notifyChefsOfUnavailability;
    toggleAvailability(userId: string, isAvailable: boolean): Promise<{
        isAvailable: boolean;
        updatedAt: Date;
    }>;
    getMyDashboard(userId: string): Promise<{
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
    getAvailableAgents(): Promise<{
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
    getPointagesHistory(agentId: string): Promise<{
        id: string;
        siteName: string;
        type: import(".prisma/client").$Enums.PointageType;
        date: string;
        location: {
            lat: number;
            lng: number;
        } | null;
    }[]>;
    getPlanning(agentId: string, monthKey?: string): Promise<{
        month: string;
        days: Record<string, DayCell>;
        stats: {
            worked: number;
            absent: number;
            assigned: number;
            pending: number;
            unavailable: number;
            conflicts: number;
        };
    }>;
    getRemuneration(agentId: string): Promise<{
        monthKey: string;
        daysWorked: number;
        totalAmount: number;
        isPaid: boolean;
        paidAt: string | null;
        details: any[];
    }[]>;
    markMonthPaid(agentId: string, monthKey: string): Promise<{
        success: boolean;
        monthKey: string;
        paidAt: string;
    }>;
    markDayAvailability(userId: string, date: string, available: boolean): Promise<{
        success: boolean;
        date: string;
        available: boolean;
    }>;
}
export {};
