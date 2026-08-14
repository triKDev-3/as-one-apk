import { IsString, IsNumber, IsEnum, IsOptional, Min } from 'class-validator';
import { MaterialState, RetentionTarget } from '@prisma/client';

export class MaterialReturnDto {
  @IsString()
  siteId: string;

  @IsString()
  itemId: string;

  @IsNumber()
  @Min(1)
  quantity: number;

  @IsEnum(MaterialState)
  state: MaterialState;

  @IsOptional()
  @IsEnum(RetentionTarget)
  retentionTarget?: RetentionTarget;

  @IsOptional()
  @IsString()
  agentId?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
