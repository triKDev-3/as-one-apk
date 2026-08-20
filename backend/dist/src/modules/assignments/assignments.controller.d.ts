import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { RespondAssignmentDto } from './dto/respond-assignment.dto';
export declare class AssignmentsController {
    private readonly service;
    constructor(service: AssignmentsService);
    create(dto: CreateAssignmentDto, req: any): Promise<{
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
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        startDate: Date;
        endDate: Date | null;
        createdById: string;
        siteId: string;
        agentId: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
    pendingTransfers(req: any): Promise<({
        assignment: {
            site: {
                id: string;
                name: string;
            };
            agent: {
                id: string;
                phone: string;
                firstName: string;
                lastName: string;
            };
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            startDate: Date;
            endDate: Date | null;
            createdById: string;
            siteId: string;
            agentId: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            isLocked: boolean;
            confirmedAt: Date | null;
            refusedAt: Date | null;
        };
        fromChef: {
            id: string;
            firstName: string;
            lastName: string;
        };
        toChef: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        status: string;
        resolvedAt: Date | null;
        assignmentId: string;
        fromChefId: string;
        toChefId: string;
    })[]>;
    listChefs(): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
    }[]>;
    getBySite(siteId: string): Promise<({
        agent: {
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
            rankingScore: number;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        startDate: Date;
        endDate: Date | null;
        createdById: string;
        siteId: string;
        agentId: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    })[]>;
    resolveTransfer(id: string, accept: boolean, req: any): Promise<{
        ok: boolean;
        status: string;
    }>;
    respond(id: string, dto: RespondAssignmentDto, req: any): Promise<{
        agent: {
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        startDate: Date;
        endDate: Date | null;
        createdById: string;
        siteId: string;
        agentId: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
    requestTransfer(id: string, toChefId: string, req: any): Promise<{
        id: string;
        createdAt: Date;
        status: string;
        resolvedAt: Date | null;
        assignmentId: string;
        fromChefId: string;
        toChefId: string;
    }>;
}
