import { IsString, IsDateString, IsOptional } from 'class-validator';

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
}
