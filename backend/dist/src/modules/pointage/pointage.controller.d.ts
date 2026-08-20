import { PointageService } from './pointage.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
export declare class PointageController {
    private readonly service;
    constructor(service: PointageService);
    create(dto: CreatePointageDto, req: any): Promise<{
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
    getMyPointages(req: any): Promise<({
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
