import { MaterialState, RetentionTarget } from '@prisma/client';
export declare class MaterialReturnDto {
    siteId: string;
    itemId: string;
    quantity: number;
    state: MaterialState;
    retentionTarget?: RetentionTarget;
    agentId?: string;
    notes?: string;
}
