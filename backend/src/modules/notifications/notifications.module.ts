import { Global, Module } from '@nestjs/common';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { FcmService } from './fcm.service';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsGateway, NotificationsService, FcmService],
  exports: [NotificationsGateway, NotificationsService, FcmService],
})
export class NotificationsModule {}
