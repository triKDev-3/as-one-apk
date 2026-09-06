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
    return this.service.getAgentsDetails(
      type,
      req.user.id,
      req.user.role,
      all === 'true',
    );
  }

  @Get('agents-by-site')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getAgentsBySite(@Query('all') all: string, @Request() req: any) {
    return this.service.getAgentsBySite(
      req.user.id,
      req.user.role,
      all === 'true',
    );
  }

  @Get('calendar')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getCalendar(
    @Query('month') month: string,
    @Query('all') all: string,
    @Query('siteId') siteId: string,
    @Request() req: any,
  ) {
    const monthKey =
      month && /^\d{4}-\d{2}$/.test(month)
        ? month
        : new Date().toISOString().slice(0, 7);
    return this.service.getChefCalendar(
      req.user.id,
      req.user.role,
      monthKey,
      all === 'true',
      siteId || undefined,
    );
  }

  /** Historique des interventions (affectations) — filtrable */
  @Get('interventions')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getInterventions(
    @Query('from') from: string,
    @Query('to') to: string,
    @Query('siteId') siteId: string,
    @Query('status') status: string,
    @Query('all') all: string,
    @Request() req: any,
  ) {
    return this.service.getInterventionsHistory({
      userId: req.user.id,
      role: req.user.role,
      all: all === 'true',
      from,
      to,
      siteId,
      status,
    });
  }
}
