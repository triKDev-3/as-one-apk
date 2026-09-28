import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  MinLength,
} from 'class-validator';
import { SiteType } from '@prisma/client';

export class UpdateSiteDto {
  @IsOptional()
  @IsString()
  @MinLength(2, { message: 'Nom du site requis' })
  name?: string;

  @IsOptional()
  @IsEnum(SiteType, { message: 'Type de site invalide' })
  type?: SiteType;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsDateString({}, { message: 'Date de début invalide' })
  startDate?: string | null;

  @IsOptional()
  @IsDateString({}, { message: 'Date de fin invalide' })
  endDate?: string | null;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  dailyRate?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  nightRate?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  sundayRate?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  bonusAmount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  monthlySalary?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  fixedAmount?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
