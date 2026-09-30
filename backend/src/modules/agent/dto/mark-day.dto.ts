import { IsBoolean, IsOptional, IsString, Matches } from 'class-validator';

export class MarkDayAvailabilityDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Date invalide (format AAAA-MM-JJ)',
  })
  date: string;

  @IsBoolean({ message: 'available doit être vrai ou faux' })
  available: boolean;

  /** Si true : annule les affectations actives qui couvrent ce jour. */
  @IsOptional()
  @IsBoolean()
  cancelAssignments?: boolean;
}

export class MarkMonthPaidDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}$/, { message: 'Mois invalide (format AAAA-MM)' })
  monthKey: string;
}
