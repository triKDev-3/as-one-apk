import { Controller, Get, Post, Body, Param, Patch, Query, UseGuards, Request } from '@nestjs/common';
import { IncidentsService } from './incidents.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('incidents')
@UseGuards(JwtAuthGuard, RolesGuard)
export class IncidentsController {
  constructor(private readonly service: IncidentsService) {}

  @Post()
  @Roles(Role.CHEF, Role.ADMIN, Role.MAGASINIER)
  create(@Body() dto: CreateIncidentDto, @Request() req: any) {
    return this.service.create(dto, req.user.id);
  }

  @Get()
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE, Role.MAGASINIER)
  list(
    @Query('siteId') siteId?: string,
    @Query('status') status?: string,
  ) {
    return this.service.list({ siteId, status });
  }

  @Patch(':id/resolve')
  @Roles(Role.CHEF, Role.ADMIN)
  resolve(@Param('id') id: string, @Request() req: any) {
    return this.service.resolve(id, req.user.id, req.user.role);
  }
}
