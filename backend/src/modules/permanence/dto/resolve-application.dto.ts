import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class ResolvePermanenceApplicationDto {
  @IsBoolean({ message: 'accept doit être vrai ou faux' })
  accept: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  rejectMessage?: string;
}
