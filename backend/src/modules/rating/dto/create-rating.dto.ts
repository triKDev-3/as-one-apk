import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class CreateRatingDto {
  @IsString()
  @MinLength(8, { message: 'Affectation invalide' })
  assignmentId: string;

  @IsString()
  @MinLength(8, { message: 'Agent invalide' })
  agentId: string;

  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Note entre 1 et 5' })
  @Max(5, { message: 'Note entre 1 et 5' })
  score: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
