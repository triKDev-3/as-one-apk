import { IsOptional, IsString, Matches, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2, { message: 'Prénom trop court' })
  firstName?: string;

  @IsOptional()
  @IsString()
  @MinLength(2, { message: 'Nom trop court' })
  lastName?: string;

  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, { message: 'Numéro de téléphone invalide' })
  phone?: string;

  @IsOptional()
  @IsString()
  mobileMoneyOperator?: string;
}

export class ChangePasswordDto {
  @IsString()
  @MinLength(6, { message: 'Mot de passe actuel requis' })
  currentPassword: string;

  @IsString()
  @MinLength(6, { message: 'Nouveau mot de passe : 6 caractères minimum' })
  newPassword: string;
}
