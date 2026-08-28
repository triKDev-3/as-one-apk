import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { StatsService } from './stats.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('stats')
@UseGuards(JwtAuthGuard, RolesGuard)
export class StatsController {
  constructor(private readonly service: StatsService) {}

  @Get('live')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getLiveStats(@Query('all') all: string, @Request() req: any) {
    return this.service.getLiveStats(req.user.id, req.user.role, all === 'true');
  }

  @Get('agents-details')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getAgentsDetails(
    @Query('type') type: string,
    @Query('all') all: string,
    @Request() req: any,
  ) {
    return this.service.getAgentsDetails(type, req.user.id, req.user.role, all === 'true');
  }

  @Get('agents-by-site')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getAgentsBySite(@Query('all') all: string, @Request() req: any) {
    return this.service.getAgentsBySite(req.user.id, req.user.role, all === 'true');
  }
}
