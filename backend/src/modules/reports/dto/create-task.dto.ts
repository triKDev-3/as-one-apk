import { IsString, IsOptional, IsDateString, MinLength } from 'class-validator';

export class CreateTaskDto {
  @IsString()
  @MinLength(1, { message: 'Veuillez d\'abord saisir la tâche.' })
  description: string;

  @IsOptional()
  @IsDateString()
  performedAt?: string;
}