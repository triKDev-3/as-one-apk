import {
  IsString,
  IsNotEmpty,
  IsDate,
  IsOptional,
  IsEnum,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { AssignmentStatus } from '@prisma/client';

export class CreateAssignmentDto {
  @IsString()
  @IsNotEmpty()
  siteId: string;

  @IsString()
  @IsNotEmpty()
  agentId: string;

  @IsDate()
  @Transform(({ value }) => new Date(value))
  startDate: Date;

  @IsDate()
  @Transform(({ value }) => new Date(value))
  @IsOptional()
  endDate?: Date;

  @IsOptional()
  @IsString()
  missionType?: string;
}

export class UpdateAssignmentStatusDto {
  @IsString()
  @IsNotEmpty()
  assignmentId: string;

  @IsEnum(AssignmentStatus)
  status: AssignmentStatus;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class ConfirmAssignmentDto {
  @IsString()
  @IsNotEmpty()
  assignmentId: string;
}

export class RefuseAssignmentDto {
  @IsString()
  @IsNotEmpty()
  assignmentId: string;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class TransferAssignmentDto {
  @IsString()
  @IsNotEmpty()
  assignmentId: string;

  @IsString()
  @IsNotEmpty()
  toChefId: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
