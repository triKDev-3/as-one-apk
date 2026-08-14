import { IsString, IsOptional, IsIn } from 'class-validator';

export class CreateIncidentDto {
  @IsString()
  siteId: string;

  @IsString()
  description: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsIn(['DEGAT', 'MATERIEL', 'SECURITE', 'AUTRE'])
  type?: string;

  @IsOptional()
  @IsIn(['BASSE', 'MOYENNE', 'HAUTE'])
  severity?: string;
}
