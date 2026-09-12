import { IsString, MaxLength, MinLength } from 'class-validator';

export class UpdateReportSummaryDto {
  @IsString()
  @MinLength(2, { message: 'Le résumé est requis' })
  @MaxLength(4000)
  summary: string;
}
