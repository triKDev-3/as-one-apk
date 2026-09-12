import { IsBoolean, IsString, Matches } from 'class-validator';

export class MarkDayAvailabilityDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Date invalide (format AAAA-MM-JJ)',
  })
  date: string;

  @IsBoolean({ message: 'available doit être vrai ou faux' })
  available: boolean;
}

export class MarkMonthPaidDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}$/, { message: 'Mois invalide (format AAAA-MM)' })
  monthKey: string;
}
