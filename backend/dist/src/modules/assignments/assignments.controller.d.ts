import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { RespondAssignmentDto } from './dto/respond-assignment.dto';
export declare class AssignmentsController {
    private readonly service;
    constructor(service: AssignmentsService);
    create(dto: CreateAssignmentDto, req: any): Promise<any>;
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
            siteId: string;
            agentId: string;
            createdById: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            startDate: Date;
            endDate: Date | null;
            isLocked: boolean;
            missionType: string | null;
            routineDays: import("@prisma/client/runtime/library").JsonValue | null;
            fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
            confirmedAt: Date | null;
            refusedAt: Date | null;
            createdAt: Date;
            updatedAt: Date;
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
        status: string;
        createdAt: Date;
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
        siteId: string;
        agentId: string;
        createdById: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        startDate: Date;
        endDate: Date | null;
        isLocked: boolean;
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    getAvailableAgents(siteId?: string): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        phone: string;
        contractType: string;
        rankingScore: number;
        avgScore: number | null;
        daysWorked: number;
        isAvailable: boolean;
        isLockedElsewhere: boolean;
    }[]>;
    releaseAgent(id: string, req: any): Promise<{
        id: string;
        siteId: string;
        agentId: string;
        createdById: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        startDate: Date;
        endDate: Date | null;
        isLocked: boolean;
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
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
        siteId: string;
        agentId: string;
        createdById: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        startDate: Date;
        endDate: Date | null;
        isLocked: boolean;
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    requestTransfer(id: string, toChefId: string, req: any): Promise<{
        id: string;
        status: string;
        createdAt: Date;
        resolvedAt: Date | null;
        assignmentId: string;
        fromChefId: string;
        toChefId: string;
    }>;
}
