import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
export declare class PointageService {
    private readonly prisma;
    private readonly notifications;
    private readonly notify;
    constructor(prisma: PrismaService, notifications: NotificationsGateway, notify: NotificationsService);
    private resolveCalendarConflicts;
    create(dto: CreatePointageDto, createdById: string): Promise<{
        siteId: string;
        type: import(".prisma/client").$Enums.PointageType;
        results: Record<string, unknown>[];
        successCount: number;
        skippedCount: number;
        autoConfirmedCount: number;
        autoCancelledCount: number;
    }>;
    list(filters?: {
        siteId?: string;
        date?: string;
        type?: string;
    }): Promise<({
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
    getByAgent(agentId: string, limit?: number): Promise<({
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
