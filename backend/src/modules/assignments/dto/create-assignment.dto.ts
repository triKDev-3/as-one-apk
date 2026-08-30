import { IsString, IsDateString, IsOptional, IsArray, IsNumber } from 'class-validator';

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
}
