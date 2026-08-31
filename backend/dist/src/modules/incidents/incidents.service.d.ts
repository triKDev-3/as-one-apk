import { PrismaService } from '../../prisma/prisma.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { Role } from '@prisma/client';
import { ApplyPenaltyDto } from './dto/apply-penalty.dto';
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
        siteId: string;
        status: string;
        createdAt: Date;
        resolvedAt: Date | null;
        type: string;
        photoUrl: string | null;
        description: string;
        severity: string;
        reportedById: string;
    }>;
    list(filters?: {
        siteId?: string;
        status?: string;
    }): Promise<{
        id: string;
        siteId: string;
        status: string;
        createdAt: Date;
        resolvedAt: Date | null;
        type: string;
        photoUrl: string | null;
        description: string;
        severity: string;
        reportedById: string;
    }[]>;
    applyPenalty(incidentId: string, dto: ApplyPenaltyDto, appliedById: string): Promise<any>;
    resolve(id: string, userId: string, role: Role): Promise<{
        id: string;
        siteId: string;
        status: string;
        createdAt: Date;
        resolvedAt: Date | null;
        type: string;
        photoUrl: string | null;
        description: string;
        severity: string;
        reportedById: string;
    }>;
}
