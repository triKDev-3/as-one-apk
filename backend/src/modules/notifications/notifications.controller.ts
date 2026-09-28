import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { IsOptional, IsString, MinLength } from 'class-validator';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

class RegisterTokenDto {
  @IsString()
  @MinLength(20)
  token: string;

  @IsOptional()
  @IsString()
  platform?: string;
}

class RemoveTokenDto {
  @IsString()
  @MinLength(20)
  token: string;
}

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

  /** Enregistre le token FCM / appareil pour le push système */
  @Post('device-token')
  registerToken(@Request() req: any, @Body() dto: RegisterTokenDto) {
    return this.service.registerDevice(
      req.user.id,
      dto.token,
      dto.platform,
    );
  }

  @Delete('device-token')
  removeToken(@Request() req: any, @Body() dto: RemoveTokenDto) {
    return this.service.removeDevice(req.user.id, dto.token);
  }
}
