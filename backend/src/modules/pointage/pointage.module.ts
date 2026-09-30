import { Module } from '@nestjs/common';
import { PointageService } from './pointage.service';
import { PointageController } from './pointage.controller';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [PointageController],
  providers: [PointageService],
  exports: [PointageService],
})
export class PointageModule {}
