import { IsDateString, IsInt, IsString, Min, MinLength } from 'class-validator';

export class CreateVehicleAlertDto {
  @IsString()
  @MinLength(2, { message: 'Nom du véhicule requis' })
  vehicleName: string;

  @IsString()
  @MinLength(2, { message: 'Type d\'alerte requis' })
  alertType: string;

  @IsDateString({}, { message: 'Date invalide' })
  lastDate: string;

  @IsInt()
  @Min(1, { message: 'La validité doit être d\'au moins 1 jour' })
  validityDays: number;
}
