import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
export declare class AssignmentsService {
    private readonly prisma;
    private readonly notifications;
    constructor(prisma: PrismaService, notifications: NotificationsGateway);
    create(dto: CreateAssignmentDto, chefId: string): Promise<{
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
    confirmOrRefuse(assignmentId: string, agentId: string, accept: boolean): Promise<{
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
    requestTransfer(assignmentId: string, fromChefId: string, toChefId: string): Promise<{
        id: string;
        createdAt: Date;
        status: string;
        resolvedAt: Date | null;
        assignmentId: string;
        fromChefId: string;
        toChefId: string;
    }>;
    listPendingTransfers(chefId: string): Promise<({
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
    resolveTransfer(transferId: string, chefId: string, accept: boolean): Promise<{
        ok: boolean;
        status: string;
    }>;
    listChefs(): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
    }[]>;
}
