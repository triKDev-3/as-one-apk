import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class PermanenceSlotDto {
  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'Heure de début invalide (HH:mm)',
  })
  startTime: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: 'Heure de fin invalide (HH:mm)',
  })
  endTime: string;

  @IsNumber()
  @Min(0, { message: 'Le salaire doit être positif' })
  salary: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  requiredAgents?: number;

  @IsOptional()
  @IsString()
  @MinLength(1)
  label?: string;
}

export class CreatePermanenceScheduleDto {
  @IsString({ message: 'Site requis' })
  @MinLength(8, { message: 'Identifiant de site invalide' })
  siteId: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  title?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  workDaysPerWeek?: number;

  @IsArray()
  @ArrayMinSize(1, { message: 'Au moins un créneau (intervalle) est requis' })
  @ValidateNested({ each: true })
  @Type(() => PermanenceSlotDto)
  slots: PermanenceSlotDto[];
}
