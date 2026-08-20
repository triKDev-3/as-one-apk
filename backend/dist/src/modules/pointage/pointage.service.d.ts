import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
export declare class PointageService {
    private readonly prisma;
    private readonly notifications;
    constructor(prisma: PrismaService, notifications: NotificationsGateway);
    create(dto: CreatePointageDto, createdById: string): Promise<{
        siteId: string;
        type: import(".prisma/client").$Enums.PointageType;
        results: ({
            agentId: string;
            status: string;
            reason: string;
            pointage?: undefined;
        } | {
            agentId: string;
            status: string;
            pointage: {
                agent: {
                    id: string;
                    phone: string;
                    firstName: string;
                    lastName: string;
                };
            } & {
                id: string;
                type: import(".prisma/client").$Enums.PointageType;
                createdById: string | null;
                siteId: string;
                agentId: string;
                assignmentId: string | null;
                photoUrl: string | null;
                latitude: number | null;
                longitude: number | null;
                notedAt: Date;
            };
            reason?: undefined;
        })[];
        successCount: number;
        skippedCount: number;
    }>;
    getBySite(siteId: string, date?: string): Promise<({
        agent: {
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PointageType;
        createdById: string | null;
        siteId: string;
        agentId: string;
        assignmentId: string | null;
        photoUrl: string | null;
        latitude: number | null;
        longitude: number | null;
        notedAt: Date;
    })[]>;
    getByAgent(agentId: string, limit?: number): Promise<({
        site: {
            id: string;
            name: string;
            type: import(".prisma/client").$Enums.SiteType;
        };
    } & {
        id: string;
        type: import(".prisma/client").$Enums.PointageType;
        createdById: string | null;
        siteId: string;
        agentId: string;
        assignmentId: string | null;
        photoUrl: string | null;
        latitude: number | null;
        longitude: number | null;
        notedAt: Date;
    })[]>;
}
