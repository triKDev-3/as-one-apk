import {
  Controller,
  Get,
  Patch,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  list(@Request() req: any) {
    return this.service.list(req.user.id);
  }

  @Get('unread-count')
  unread(@Request() req: any) {
    return this.service.unreadCount(req.user.id).then((count) => ({ count }));
  }

  @Patch('read-all')
  markAllRead(@Request() req: any) {
    return this.service.markAllRead(req.user.id);
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string, @Request() req: any) {
    return this.service.markRead(id, req.user.id);
  }
}
