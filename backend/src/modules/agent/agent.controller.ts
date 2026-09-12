import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ToggleAvailabilityDto } from './dto/toggle-availability.dto';
import { MarkDayAvailabilityDto, MarkMonthPaidDto } from './dto/mark-day.dto';
import { AgentService } from './agent.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('agent')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  @Patch('availability')
  @Roles(Role.AGENT)
  toggleAvailability(@Request() req: any, @Body() dto: ToggleAvailabilityDto) {
    return this.agentService.toggleAvailability(req.user.id, dto.isAvailable);
  }

  @Get('me')
  @Roles(Role.AGENT)
  getMyDashboard(@Request() req: any) {
    return this.agentService.getMyDashboard(req.user.id);
  }

  @Get('pointages')
  @Roles(Role.AGENT)
  getPointagesHistory(@Request() req: any) {
    return this.agentService.getPointagesHistory(req.user.id);
  }

  /** Planning mensuel — ?month=yyyy-MM */
  @Get('calendar')
  @Roles(Role.AGENT)
  getPlanning(@Request() req: any, @Query('month') month?: string) {
    return this.agentService.getPlanning(req.user.id, month);
  }

  @Get('remuneration')
  @Roles(Role.AGENT)
  getRemuneration(@Request() req: any) {
    return this.agentService.getRemuneration(req.user.id);
  }

  @Post('remuneration/mark-paid')
  @Roles(Role.AGENT)
  markMonthPaid(@Request() req: any, @Body() dto: MarkMonthPaidDto) {
    return this.agentService.markMonthPaid(req.user.id, dto.monthKey);
  }

  @Get('available')
  @Roles(Role.CHEF, Role.ADMIN)
  getAvailable() {
    return this.agentService.getAvailableAgents();
  }

  @Post('availability-mark')
  @Roles(Role.AGENT)
  markDayAvailability(
    @Request() req: any,
    @Body() dto: MarkDayAvailabilityDto,
  ) {
    return this.agentService.markDayAvailability(
      req.user.id,
      dto.date,
      dto.available,
    );
  }
}
