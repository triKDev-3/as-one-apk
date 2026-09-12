import {
  IsString,
  IsNotEmpty,
  IsEnum,
  IsOptional,
  IsNumber,
} from 'class-validator';
import { PointageType } from '@prisma/client';

export class CreatePointageDto {
  @IsString()
  @IsNotEmpty()
  assignmentId?: string;

  @IsString()
  @IsNotEmpty()
  siteId: string;

  @IsString()
  @IsNotEmpty()
  agentId: string;

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

export class PointagePhotoUploadDto {
  @IsString()
  @IsNotEmpty()
  assignmentId: string;

  @IsString()
  @IsNotEmpty()
  base64Photo: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;
}
