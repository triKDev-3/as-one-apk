import { IsString, IsNumber, IsOptional, Min } from 'class-validator';

export class MaterialOutDto {
  @IsString()
  siteId: string;

  @IsString()
  itemId: string;

  @IsNumber()
  @Min(1)
  quantity: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
