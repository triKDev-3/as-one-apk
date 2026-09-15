import { PartialType } from '@nestjs/mapped-types';
import { CreateTrainingVideoDto } from './create-training-video.dto';

export class UpdateTrainingVideoDto extends PartialType(CreateTrainingVideoDto) {}
