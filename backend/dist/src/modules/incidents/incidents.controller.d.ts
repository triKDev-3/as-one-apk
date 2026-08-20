import { IncidentsService } from './incidents.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
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
        description: string;
        status: string;
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
    resolve(id: string, req: any): Promise<{
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
