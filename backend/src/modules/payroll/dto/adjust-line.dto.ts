import { IsNumber, IsOptional, Min } from 'class-validator';

export class AdjustLineDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  primes?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  retenues?: number;
}
