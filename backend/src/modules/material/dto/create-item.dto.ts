import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';

export class CreateMaterialItemDto {
  @IsString()
  @MinLength(2, { message: 'Nom de l\'article requis' })
  name: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  refCode?: string;

  @IsIn(['CONSOMMABLE', 'EQUIPEMENT', 'consignable', 'consommable'], {
    message: 'Catégorie invalide',
  })
  category: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0, { message: 'Prix unitaire invalide' })
  unitPrice: number;

  @IsOptional()
  @IsBoolean()
  returnRequired?: boolean;
}

export class UpdateMaterialItemDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsString()
  refCode?: string;

  @IsOptional()
  @IsIn(['CONSOMMABLE', 'EQUIPEMENT'])
  category?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  unitPrice?: number;

  @IsOptional()
  @IsBoolean()
  returnRequired?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
