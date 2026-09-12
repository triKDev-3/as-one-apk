import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateIncidentDto {
  @IsString()
  @MinLength(8, { message: 'Site invalide' })
  siteId: string;

  @IsString()
  @MinLength(3, { message: 'Décrivez l\'incident (3 caractères min.)' })
  description: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsIn(['DEGAT', 'MATERIEL', 'SECURITE', 'AUTRE'], {
    message: 'Type d\'incident invalide',
  })
  type?: string;

  @IsOptional()
  @IsIn(['BASSE', 'MOYENNE', 'HAUTE'], { message: 'Gravité invalide' })
  severity?: string;
}
