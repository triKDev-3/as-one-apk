import { PointageType } from '@prisma/client';
export declare class CreatePointageDto {
    siteId: string;
    agentIds: string[];
    type: PointageType;
    photoUrl?: string;
    latitude?: number;
    longitude?: number;
}
