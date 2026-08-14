import { Controller, Get, Patch, Body, UseGuards, Request } from '@nestjs/common';
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

  /** Liste des agents disponibles (pour les chefs) */
  @Get('available')
  @Roles(Role.CHEF, Role.ADMIN)
  getAvailable() {
    return this.agentService.getAvailableAgents();
  }
}
