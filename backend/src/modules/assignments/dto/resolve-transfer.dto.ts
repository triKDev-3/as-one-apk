import { IsBoolean, IsString, MinLength } from 'class-validator';

export class ResolveTransferDto {
  @IsBoolean({ message: 'accept doit être vrai ou faux' })
  accept: boolean;
}

export class RequestTransferDto {
  @IsString()
  @MinLength(8, { message: 'Chef destinataire invalide' })
  toChefId: string;
}
