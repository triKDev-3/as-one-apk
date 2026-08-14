import { Module } from '@nestjs/common';
import { PointageService } from './pointage.service';
import { PointageController } from './pointage.controller';

@Module({
  controllers: [PointageController],
  providers: [PointageService],
  exports: [PointageService],
})
export class PointageModule {}
