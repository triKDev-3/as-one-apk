import { IsString, IsNotEmpty, IsOptional, IsJSON } from 'class-validator';

export class CreateNotificationDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  body: string;

  @IsString()
  @IsNotEmpty()
  type: string;

  @IsOptional()
  @IsJSON()
  data?: Record<string, any>;
}

export class MarkNotificationAsReadDto {
  @IsString()
  @IsNotEmpty()
  notificationId: string;
}
