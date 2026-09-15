import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { RespondAssignmentDto } from './dto/respond-assignment.dto';
import { ResolveTransferDto, RequestTransferDto } from './dto/resolve-transfer.dto';
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
            createdAt: Date;
            updatedAt: Date;
            startDate: Date;
            endDate: Date | null;
            createdById: string;
            siteId: string;
            agentId: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            isLocked: boolean;
            missionType: string | null;
            routineDays: import("@prisma/client/runtime/library").JsonValue | null;
            fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
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
        assignmentId: string;
        resolvedAt: Date | null;
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
            agentProfile: {
                isAvailable: boolean;
                unavailableDates: import("@prisma/client/runtime/library").JsonValue;
            } | null;
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
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
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
        canForceMultiSite: boolean;
        lockedOnSites: {
            siteId: string;
            siteName: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
        }[];
        unavailableDates: string[];
        isUnavailableToday: boolean;
    }[]>;
    releaseAgent(id: string, req: any): Promise<{
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
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
    resolveTransfer(id: string, dto: ResolveTransferDto, req: any): Promise<{
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
        missionType: string | null;
        routineDays: import("@prisma/client/runtime/library").JsonValue | null;
        fixedSalary: import("@prisma/client/runtime/library").Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
    requestTransfer(id: string, dto: RequestTransferDto, req: any): Promise<{
        id: string;
        createdAt: Date;
        status: string;
        assignmentId: string;
        resolvedAt: Date | null;
        fromChefId: string;
        toChefId: string;
    }>;
}
