import { ReportsService } from './reports.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { CloseReportDto } from './dto/close-report.dto';
export declare class ReportsController {
    private readonly service;
    constructor(service: ReportsService);
    addTask(siteId: string, dto: CreateTaskDto, req: any): Promise<{
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
    closeReport(siteId: string, dto: CloseReportDto, req: any): Promise<{
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
    listBySite(siteId: string): Promise<({
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
    listAll(): Promise<({
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
    getOne(id: string): Promise<{
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
            exceptionalRate: import("@prisma/client/runtime/library").Decimal | null;
            bonusAmount: import("@prisma/client/runtime/library").Decimal | null;
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
