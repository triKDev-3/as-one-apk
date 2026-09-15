import { IsString, IsOptional, IsBoolean, IsInt, IsUrl } from 'class-validator';

export class CreateTrainingVideoDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  @IsUrl()
  youtubeUrl: string;

  @IsOptional()
  @IsString()
  lessonContent?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  orderIndex?: number;
}
