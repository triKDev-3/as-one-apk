import { IsString, IsNumber, IsIn, Min } from 'class-validator';

export class CreateMaterialItemDto {
  @IsString()
  name: string;

  @IsIn(['consignable', 'consommable'])
  category: string;

  @IsNumber()
  @Min(0)
  unitPrice: number;
}
