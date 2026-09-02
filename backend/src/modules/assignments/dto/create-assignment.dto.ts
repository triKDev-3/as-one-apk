import {
  IsString,
  IsDateString,
  IsOptional,
  IsArray,
  IsNumber,
  IsBoolean,
} from 'class-validator';

export class CreateAssignmentDto {
  @IsString()
  siteId: string;

  @IsString()
  agentId: string;

  @IsDateString()
  startDate: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsString()
  missionType?: string;

  @IsOptional()
  @IsArray()
  routineDays?: number[];

  @IsOptional()
  @IsNumber()
  fixedSalary?: number;

  /**
   * Urgence multi-sites : autorise une 2e affectation si l'agent
   * a déjà un pointage DEPART le jour de début (terrain validé).
   */
  @IsOptional()
  @IsBoolean()
  forceMultiSite?: boolean;
}
