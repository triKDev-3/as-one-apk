import { SiteType } from '@prisma/client';
export declare class CreateSiteDto {
    name: string;
    type: SiteType;
    address?: string;
    location?: string;
    startDate?: string;
    endDate?: string;
    dailyRate?: number;
    nightRate?: number;
    sundayRate?: number;
    bonusAmount?: number;
    monthlySalary?: number;
    fixedAmount?: number;
}
