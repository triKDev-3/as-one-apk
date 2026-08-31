import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { Prisma } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { WhatsappService } from '../whatsapp/whatsapp.service';
export declare class AssignmentsService {
    private readonly prisma;
    private readonly notifications;
    private readonly whatsapp;
    constructor(prisma: PrismaService, notifications: NotificationsGateway, whatsapp: WhatsappService);
    create(dto: CreateAssignmentDto, chefId: string): Promise<any>;
    confirmOrRefuse(assignmentId: string, agentId: string, accept: boolean): Promise<{
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
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
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
        siteId: string;
        agentId: string;
        createdById: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        startDate: Date;
        endDate: Date | null;
        isLocked: boolean;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    requestTransfer(assignmentId: string, fromChefId: string, toChefId: string): Promise<{
        id: string;
        status: string;
        createdAt: Date;
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
            siteId: string;
            agentId: string;
            createdById: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            startDate: Date;
            endDate: Date | null;
            isLocked: boolean;
            missionType: string | null;
            routineDays: Prisma.JsonValue | null;
            fixedSalary: Prisma.Decimal | null;
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
    releaseAgent(assignmentId: string, chefId: string): Promise<{
        id: string;
        siteId: string;
        agentId: string;
        createdById: string;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        startDate: Date;
        endDate: Date | null;
        isLocked: boolean;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
}
