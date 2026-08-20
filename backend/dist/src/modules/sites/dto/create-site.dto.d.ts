import { SiteType } from '@prisma/client';
export declare class CreateSiteDto {
    name: string;
    type: SiteType;
    address?: string;
    location?: string;
    startDate?: string;
    endDate?: string;
    dailyRate?: number;
    exceptionalRate?: number;
    bonusAmount?: number;
}
