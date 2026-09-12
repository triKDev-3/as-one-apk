import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
} from 'class-validator';

export class CreateAssignmentDto {
  @IsString()
  @MinLength(8, { message: 'Site invalide' })
  siteId: string;

  @IsString()
  @MinLength(8, { message: 'Agent invalide' })
  agentId: string;

  @IsDateString({}, { message: 'Date de début invalide' })
  startDate: string;

  @IsOptional()
  @IsDateString({}, { message: 'Date de fin invalide' })
  endDate?: string;

  @IsOptional()
  @IsIn(['TEMPORAIRE', 'PERMANENTE', 'ROUTINE', 'INTERVENTION', 'REMPLACEMENT'], {
    message: 'Type de mission invalide',
  })
  missionType?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(7)
  @IsInt({ each: true })
  @Min(0, { each: true })
  @Max(6, { each: true })
  routineDays?: number[];

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  fixedSalary?: number;

  /**
   * Urgence multi-sites : autorise une 2e affectation si l'agent
   * a déjà un pointage DEPART le jour de début (terrain validé).
   */
  @IsOptional()
  @IsBoolean()
  forceMultiSite?: boolean;
}
