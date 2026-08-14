import { IsString, IsOptional, IsDateString } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  description: string;

  @IsOptional()
  @IsDateString()
  performedAt?: string;
}
