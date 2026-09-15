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
        createdAt: Date;
        type: string;
        siteId: string;
        status: string;
        description: string;
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
        penalties: ({
            agent: {
                id: string;
                firstName: string;
                lastName: string;
            } | null;
        } & {
            id: string;
            createdAt: Date;
            agentId: string | null;
            target: import(".prisma/client").$Enums.RetentionTarget;
            amount: import("@prisma/client/runtime/library").Decimal;
            reason: string | null;
            appliedById: string;
            incidentId: string;
        })[];
    } & {
        id: string;
        createdAt: Date;
        type: string;
        siteId: string;
        status: string;
        description: string;
        resolvedAt: Date | null;
        photoUrl: string | null;
        severity: string;
        reportedById: string;
    })[]>;
    applyPenalty(incidentId: string, dto: ApplyPenaltyDto, appliedById: string): Promise<({
        agent: {
            id: string;
            firstName: string;
            lastName: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        agentId: string | null;
        target: import(".prisma/client").$Enums.RetentionTarget;
        amount: import("@prisma/client/runtime/library").Decimal;
        reason: string | null;
        appliedById: string;
        incidentId: string;
    }) | {
        ok: boolean;
        agents: number;
        amountEach: number;
    }>;
    resolve(id: string, userId: string, role: Role): Promise<{
        id: string;
        createdAt: Date;
        type: string;
        siteId: string;
        status: string;
        description: string;
        resolvedAt: Date | null;
        photoUrl: string | null;
        severity: string;
        reportedById: string;
    }>;
}
