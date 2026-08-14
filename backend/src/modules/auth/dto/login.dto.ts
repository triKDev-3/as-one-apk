import { IsString, MinLength, Matches } from 'class-validator';

export class LoginDto {
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, { message: 'Numéro de téléphone invalide' })
  phone: string;

  @IsString()
  @MinLength(6)
  password: string;
}
