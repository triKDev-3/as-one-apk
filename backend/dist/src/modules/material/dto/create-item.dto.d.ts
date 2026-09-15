export declare class CreateMaterialItemDto {
    name: string;
    refCode?: string;
    category: string;
    unitPrice: number;
    returnRequired?: boolean;
}
export declare class UpdateMaterialItemDto {
    name?: string;
    refCode?: string;
    category?: string;
    unitPrice?: number;
    returnRequired?: boolean;
    isActive?: boolean;
}
