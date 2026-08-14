import { IsString, IsEnum, IsOptional, IsNumber, IsDateString } from 'class-validator';
import { SiteType } from '@prisma/client';

export class CreateSiteDto {
  @IsString()
  name: string;

  @IsEnum(SiteType)
  type: SiteType;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsNumber()
  dailyRate?: number;

  @IsOptional()
  @IsNumber()
  exceptionalRate?: number;

  @IsOptional()
  @IsNumber()
  bonusAmount?: number;
}
