import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { MaterialState, RetentionTarget } from '@prisma/client';

export class FicheLineInputDto {
  @IsString()
  @MinLength(8)
  itemId: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  qtyRequested: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  qtyDelivered?: number;

  @IsOptional()
  @IsString()
  outNotes?: string;
}

export class CreateMaterialFicheDto {
  @IsString()
  @MinLength(8)
  siteId: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'Sélectionnez au moins un article' })
  @ValidateNested({ each: true })
  @Type(() => FicheLineInputDto)
  lines: FicheLineInputDto[];

  @IsOptional()
  @IsDateString()
  plannedReturn?: string;

  @IsOptional()
  @IsString()
  sector?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  spaceCount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  personCount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  dayCount?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateMaterialFicheDto {
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => FicheLineInputDto)
  lines?: FicheLineInputDto[];

  @IsOptional()
  @IsDateString()
  plannedReturn?: string;

  @IsOptional()
  @IsString()
  sector?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  spaceCount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  personCount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  dayCount?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class ReturnLineDto {
  @IsString()
  @MinLength(8)
  lineId: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  qtyReturned: number;

  @IsOptional()
  @IsEnum(MaterialState)
  returnState?: MaterialState;

  @IsOptional()
  @IsBoolean()
  isLost?: boolean;

  @IsOptional()
  @IsBoolean()
  isChecked?: boolean;

  @IsOptional()
  @IsString()
  returnNotes?: string;
}

export class CheckReturnDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ReturnLineDto)
  lines: ReturnLineDto[];
}

export class ApplySanctionDto {
  @IsString()
  @MinLength(8)
  lineId: string;

  @IsEnum(RetentionTarget)
  target: RetentionTarget;

  @IsOptional()
  @IsString()
  agentId?: string;

  @Type(() => Number)
  @IsNumber()
  @Min(1)
  amount: number;

  @IsOptional()
  @IsString()
  reason?: string;
}
