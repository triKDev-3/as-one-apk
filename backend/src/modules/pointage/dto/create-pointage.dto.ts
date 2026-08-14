import {
  IsString,
  IsEnum,
  IsArray,
  ArrayMinSize,
  IsOptional,
  IsNumber,
} from 'class-validator';
import { PointageType } from '@prisma/client';

export class CreatePointageDto {
  @IsString()
  siteId: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  agentIds: string[];

  @IsEnum(PointageType)
  type: PointageType;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
