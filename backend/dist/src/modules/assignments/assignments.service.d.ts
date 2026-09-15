import { PrismaService } from '../../prisma/prisma.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { Prisma } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { WhatsappService } from '../whatsapp/whatsapp.service';
export declare class AssignmentsService {
    private readonly prisma;
    private readonly notifications;
    private readonly notify;
    private readonly whatsapp;
    constructor(prisma: PrismaService, notifications: NotificationsGateway, notify: NotificationsService, whatsapp: WhatsappService);
    private findMultiSiteConflicts;
    private hasDepartOnDate;
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
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
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
            agentProfile: {
                isAvailable: boolean;
                unavailableDates: Prisma.JsonValue;
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
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    })[]>;
    requestTransfer(assignmentId: string, fromChefId: string, toChefId: string): Promise<{
        id: string;
        createdAt: Date;
        status: string;
        assignmentId: string;
        resolvedAt: Date | null;
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
            missionType: string | null;
            routineDays: Prisma.JsonValue | null;
            fixedSalary: Prisma.Decimal | null;
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
        canForceMultiSite: boolean;
        lockedOnSites: {
            siteId: string;
            siteName: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
        }[];
        unavailableDates: string[];
        isUnavailableToday: boolean;
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
        status: import(".prisma/client").$Enums.AssignmentStatus;
        isLocked: boolean;
        missionType: string | null;
        routineDays: Prisma.JsonValue | null;
        fixedSalary: Prisma.Decimal | null;
        confirmedAt: Date | null;
        refusedAt: Date | null;
    }>;
}
