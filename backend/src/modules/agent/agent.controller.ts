import { Controller, Get, Patch, Post, Body, UseGuards, Request } from '@nestjs/common';
import { ToggleAvailabilityDto } from './dto/toggle-availability.dto';
import { AgentService } from './agent.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('agent')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  /** Gros bouton disponibilité */
  @Patch('availability')
  @Roles(Role.AGENT)
  toggleAvailability(@Request() req: any, @Body() dto: ToggleAvailabilityDto) {
    return this.agentService.toggleAvailability(req.user.id, dto.isAvailable);
  }

  /** Tableau de bord agent (solde, affectations, classement) */
  @Get('me')
  @Roles(Role.AGENT)
  getMyDashboard(@Request() req: any) {
    return this.agentService.getMyDashboard(req.user.id);
  }

  /** Historique des pointages */
  @Get('pointages')
  @Roles(Role.AGENT)
  getPointagesHistory(@Request() req: any) {
    return this.agentService.getPointagesHistory(req.user.id);
  }

  /** Planning */
  @Get('calendar')
  @Roles(Role.AGENT)
  getPlanning(@Request() req: any) {
    return this.agentService.getPlanning(req.user.id);
  }

  /** Rémunération mensuelle */
  @Get('remuneration')
  @Roles(Role.AGENT)
  getRemuneration(@Request() req: any) {
    return this.agentService.getRemuneration(req.user.id);
  }

  /** Marquer un mois comme payé */
  @Post('remuneration/mark-paid')
  @Roles(Role.AGENT)
  markMonthPaid(@Request() req: any, @Body() dto: { monthKey: string }) {
    return this.agentService.markMonthPaid(req.user.id, dto.monthKey);
  }

  /** Liste des agents disponibles (pour les chefs) */
  @Get('available')
  @Roles(Role.CHEF, Role.ADMIN)
  getAvailable() {
    return this.agentService.getAvailableAgents();
  }

  /** Marquer un jour futur comme disponible ou indisponible */
  @Post('availability-mark')
  @Roles(Role.AGENT)
  markDayAvailability(
    @Request() req: any,
    @Body() dto: { date: string; available: boolean },
  ) {
    return this.agentService.markDayAvailability(req.user.id, dto.date, dto.available);
  }
}
