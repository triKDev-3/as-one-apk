import { IsEmail, IsEnum, IsOptional, IsString, Matches, MinLength } from 'class-validator';
import { AgentType, Role } from '@prisma/client';

export class CreateUserDto {
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, { message: 'Numéro de téléphone invalide' })
  phone: string;

  @IsOptional()
  @IsEmail({}, { message: 'Email invalide' })
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(6, { message: 'Mot de passe : 6 caractères minimum' })
  password?: string;

  @IsString()
  @MinLength(2, { message: 'Prénom trop court' })
  firstName: string;

  @IsString()
  @MinLength(2, { message: 'Nom trop court' })
  lastName: string;

  @IsEnum(Role, { message: 'Rôle invalide' })
  role: Role;

  @IsOptional()
  @IsEnum(AgentType, { message: 'Type d\'agent invalide' })
  agentType?: AgentType;

  @IsOptional()
  @IsString()
  mobileMoneyOperator?: string;
}
