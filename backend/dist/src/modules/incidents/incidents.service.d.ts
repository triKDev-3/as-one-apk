import { PrismaService } from '../../prisma/prisma.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { Role } from '@prisma/client';
export declare class IncidentsService {
    private readonly prisma;
    private readonly notifications;
    constructor(prisma: PrismaService, notifications: NotificationsGateway);
    create(dto: CreateIncidentDto, reportedById: string): Promise<{
        site: {
            id: string;
            name: string;
        };
        reportedBy: {
            id: string;
            firstName: string;
            lastName: string;
            role: import(".prisma/client").$Enums.Role;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        siteId: string;
        description: string;
        status: string;
        resolvedAt: Date | null;
        photoUrl: string | null;
        severity: string;
        reportedById: string;
    }>;
    list(filters?: {
        siteId?: string;
        status?: string;
    }): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
        reportedBy: {
            id: string;
            firstName: string;
            lastName: string;
            role: import(".prisma/client").$Enums.Role;
        };
    } & {
        id: string;
        createdAt: Date;
        type: string;
        siteId: string;
        description: string;
        status: string;
        resolvedAt: Date | null;
        photoUrl: string | null;
        severity: string;
        reportedById: string;
    })[]>;
    resolve(id: string, userId: string, role: Role): Promise<{
        id: string;
        createdAt: Date;
        type: string;
        siteId: string;
        description: string;
        status: string;
        resolvedAt: Date | null;
        photoUrl: string | null;
        severity: string;
        reportedById: string;
    }>;
}
