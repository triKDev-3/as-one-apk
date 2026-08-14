import { IsString, IsInt, Min, Max, IsOptional } from 'class-validator';

export class CreateRatingDto {
  @IsString()
  assignmentId: string;

  @IsString()
  agentId: string;

  @IsInt()
  @Min(1)
  @Max(5)
  score: number;

  @IsOptional()
  @IsString()
  comment?: string;
}
