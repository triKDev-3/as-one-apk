import { Controller, Post, Body, UseGuards, Request, Get } from '@nestjs/common';
import { WhatsappService } from './whatsapp.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { WhatsappPairDto } from './dto/pair.dto';

@Controller('whatsapp')
@UseGuards(JwtAuthGuard, RolesGuard)
export class WhatsappController {
  constructor(private readonly whatsappService: WhatsappService) {}

  @Post('pair')
  @Roles(Role.CHEF, Role.ADMIN)
  async requestPairing(@Request() req: any, @Body() dto: WhatsappPairDto) {
    const code = await this.whatsappService.requestPairingCode(req.user.id, dto.phone);
    return { code };
  }

  @Get('status')
  @Roles(Role.CHEF, Role.ADMIN)
  async getStatus(@Request() req: any) {
    const connected = this.whatsappService.isConnected(req.user.id);
    return { connected };
  }

  @Post('disconnect')
  @Roles(Role.CHEF, Role.ADMIN)
  async disconnect(@Request() req: any) {
    await this.whatsappService.disconnect(req.user.id);
    return { success: true };
  }
}
