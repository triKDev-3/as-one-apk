import { PointageService } from './pointage.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
export declare class PointageController {
    private readonly service;
    constructor(service: PointageService);
    create(dto: CreatePointageDto, req: any): Promise<{
        siteId: string;
        type: import(".prisma/client").$Enums.PointageType;
        results: Record<string, unknown>[];
        successCount: number;
        skippedCount: number;
        autoConfirmedCount: number;
        autoCancelledCount: number;
    }>;
    list(siteId?: string, date?: string, type?: string): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
        agent: {
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
            role: import(".prisma/client").$Enums.Role;
        };
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PointageType;
        createdById: string | null;
        siteId: string;
        agentId: string;
        assignmentId: string | null;
        photoUrl: string | null;
        latitude: number | null;
        longitude: number | null;
        notedAt: Date;
    })[]>;
    getBySite(siteId: string, date?: string): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
        agent: {
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
            role: import(".prisma/client").$Enums.Role;
        };
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PointageType;
        createdById: string | null;
        siteId: string;
        agentId: string;
        assignmentId: string | null;
        photoUrl: string | null;
        latitude: number | null;
        longitude: number | null;
        notedAt: Date;
    })[]>;
    getMyPointages(req: any): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PointageType;
        createdById: string | null;
        siteId: string;
        agentId: string;
        assignmentId: string | null;
        photoUrl: string | null;
        latitude: number | null;
        longitude: number | null;
        notedAt: Date;
    })[]>;
}
