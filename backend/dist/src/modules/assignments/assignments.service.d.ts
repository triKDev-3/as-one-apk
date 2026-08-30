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
        createdAt: Date;
        updatedAt: Date;
        startDate: Date;
        endDate: Date | null;
        createdById: string;
        siteId: string;
        agentId: string;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
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
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
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
            missionType: string | null;
            routineDays: Prisma.JsonValue | null;
            fixedSalary: Prisma.Decimal | null;
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
        createdAt: Date;
        updatedAt: Date;
        startDate: Date;
        endDate: Date | null;
        createdById: string;
        siteId: string;
        agentId: string;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
}
