import { IsOptional, IsString, IsDateString } from 'class-validator';

export class CloseReportDto {
  @IsOptional()
  @IsString()
  summary?: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
