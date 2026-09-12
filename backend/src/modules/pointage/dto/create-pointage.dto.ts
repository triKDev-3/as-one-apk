import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';
import { PointageType } from '@prisma/client';

export class CreatePointageDto {
  @IsString()
  @MinLength(8, { message: 'Site invalide' })
  siteId: string;

  @IsArray()
  @ArrayMinSize(1, { message: 'Sélectionnez au moins un agent' })
  @IsString({ each: true })
  agentIds: string[];

  /** Défaut métier : DEPART (heures de départ). ABSENT pour une absence confirmée. */
  @IsOptional()
  @IsEnum(PointageType, { message: 'Type de pointage invalide' })
  type?: PointageType;

  @IsOptional()
  @IsDateString({}, { message: 'Date de pointage invalide' })
  notedAt?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;
}
