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
    list(siteId?: string, status?: string): Promise<{
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
    applyPenalty(id: string, dto: ApplyPenaltyDto, req: any): Promise<any>;
    resolve(id: string, req: any): Promise<{
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
