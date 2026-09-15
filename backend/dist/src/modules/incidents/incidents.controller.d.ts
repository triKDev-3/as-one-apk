import { IncidentsService } from './incidents.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { ApplyPenaltyDto } from './dto/apply-penalty.dto';
export declare class IncidentsController {
    private readonly service;
    constructor(service: IncidentsService);
    create(dto: CreateIncidentDto, req: any): Promise<{
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
    list(siteId?: string, status?: string): Promise<({
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
    applyPenalty(id: string, dto: ApplyPenaltyDto, req: any): Promise<({
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
    resolve(id: string, req: any): Promise<{
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
