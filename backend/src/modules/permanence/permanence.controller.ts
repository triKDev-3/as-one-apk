import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PermanenceService } from './permanence.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('permanence')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PermanenceController {
  constructor(private readonly service: PermanenceService) {}

  @Post('schedules')
  @Roles(Role.CHEF, Role.ADMIN)
  create(@Request() req: any, @Body() body: any) {
    return this.service.createSchedule(req.user.id, body);
  }

  @Get('schedules/site/:siteId')
  @Roles(Role.CHEF, Role.ADMIN)
  listSite(@Param('siteId') siteId: string) {
    return this.service.listBySite(siteId);
  }

  @Post('schedules/:id/publish')
  @Roles(Role.CHEF, Role.ADMIN)
  publish(@Request() req: any, @Param('id') id: string) {
    return this.service.publish(id, req.user.id);
  }

  @Get('offers')
  @Roles(Role.AGENT, Role.CHEF, Role.ADMIN)
  offers() {
    return this.service.listOpenOffers();
  }

  @Post('slots/:slotId/apply')
  @Roles(Role.AGENT)
  apply(@Request() req: any, @Param('slotId') slotId: string) {
    return this.service.apply(slotId, req.user.id);
  }

  @Patch('applications/:id')
  @Roles(Role.CHEF, Role.ADMIN)
  resolve(
    @Request() req: any,
    @Param('id') id: string,
    @Body() body: { accept: boolean; rejectMessage?: string },
  ) {
    return this.service.resolveApplication(
      id,
      req.user.id,
      body.accept,
      body.rejectMessage,
    );
  }

  @Get('applications/mine')
  @Roles(Role.AGENT)
  myApps(@Request() req: any) {
    return this.service.myApplications(req.user.id);
  }
}
