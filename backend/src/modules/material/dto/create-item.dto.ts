import { Type } from 'class-transformer';
import { IsIn, IsNumber, IsString, Min, MinLength } from 'class-validator';

export class CreateMaterialItemDto {
  @IsString()
  @MinLength(2, { message: 'Nom de l\'article requis' })
  name: string;

  @IsIn(['consignable', 'consommable'], { message: 'Catégorie invalide' })
  category: string;

  @Type(() => Number)
  @IsNumber()
  @Min(0, { message: 'Prix unitaire invalide' })
  unitPrice: number;
}
