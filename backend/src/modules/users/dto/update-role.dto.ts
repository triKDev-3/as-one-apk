import { IsEnum } from 'class-validator';
import { Role } from '@prisma/client';

export class UpdateRoleDto {
  @IsEnum(Role, { message: 'Rôle invalide' })
  role: Role;
}
