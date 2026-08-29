import { Type } from 'class-transformer';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { RetentionTarget } from '@prisma/client';

export class ApplyPenaltyDto {
  @IsEnum(RetentionTarget)
  target: RetentionTarget;

  @Type(() => Number)
  @IsNumber()
  @Min(1)
  amount: number;

  @IsOptional()
  @IsString()
  agentId?: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
