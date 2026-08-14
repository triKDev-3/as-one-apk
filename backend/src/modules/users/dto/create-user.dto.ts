import { IsString, IsEnum, IsOptional, MinLength, Matches, IsEmail } from 'class-validator';
import { Role, AgentType } from '@prisma/client';

export class CreateUserDto {
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/)
  phone: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsEnum(Role)
  role: Role;

  @IsOptional()
  @IsEnum(AgentType)
  agentType?: AgentType;

  @IsOptional()
  @IsString()
  mobileMoneyOperator?: string;
}
