import { Module } from '@nestjs/common';
import { TrainingVideosService } from './training-videos.service';
import { TrainingVideosController } from './training-videos.controller';

@Module({
  controllers: [TrainingVideosController],
  providers: [TrainingVideosService],
})
export class TrainingVideosModule {}
