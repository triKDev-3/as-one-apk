import { PrismaService } from '../../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { CloseReportDto } from './dto/close-report.dto';
export declare class ReportsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    addTask(siteId: string, dto: CreateTaskDto, createdById: string): Promise<{
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        createdById: string;
        siteId: string;
        description: string;
        performedAt: Date;
    }>;
    listTasks(siteId: string): Promise<({
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        createdById: string;
        siteId: string;
        description: string;
        performedAt: Date;
    })[]>;
    closeAndGenerateReport(siteId: string, dto: CloseReportDto, createdById: string): Promise<{
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    }>;
    getReport(reportId: string): Promise<{
        site: {
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
        };
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    }>;
    listReportsBySite(siteId: string): Promise<({
        createdBy: {
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    })[]>;
    listAllReports(): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
        createdBy: {
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    })[]>;
    getLatestReportBySite(siteId: string): Promise<({
        site: {
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
        };
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    }) | null>;
    updateReportSummary(reportId: string, summary: string): Promise<{
        site: {
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
        };
        createdBy: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        siteId: string;
        status: string;
        details: import("@prisma/client/runtime/library").JsonValue;
        summary: string | null;
        closedAt: Date;
    }>;
}
