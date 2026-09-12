import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { MaterialService } from './material.service';
import { CreateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
import { CreateVehicleAlertDto } from './dto/create-alert.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('material')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MaterialController {
  constructor(private readonly service: MaterialService) {}

  // Catalogue
  @Post('items')
  @Roles(Role.ADMIN, Role.MAGASINIER)
  createItem(@Body() dto: CreateMaterialItemDto) {
    return this.service.createItem(dto);
  }

  @Get('items')
  @Roles(Role.ADMIN, Role.MAGASINIER, Role.CHEF)
  listItems(@Query('category') category?: string) {
    return this.service.listItems(category);
  }

  // Sortie
  @Post('out')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  materialOut(@Body() dto: MaterialOutDto, @Request() req: any) {
    return this.service.materialOut(dto, req.user.id);
  }

  // Retour + retenue
  @Post('return')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  materialReturn(@Body() dto: MaterialReturnDto, @Request() req: any) {
    return this.service.materialReturn(dto, req.user.id);
  }

  // Historique par site
  @Get('site/:siteId')
  @Roles(Role.MAGASINIER, Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getBySite(@Param('siteId') siteId: string) {
    return this.service.getMovementsBySite(siteId);
  }

  // Alertes véhicules
  @Post('vehicle-alerts')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  createAlert(@Body() body: CreateVehicleAlertDto) {
    return this.service.createVehicleAlert(body);
  }

  @Get('vehicle-alerts')
  @Roles(Role.ADMIN, Role.MAGASINIER, Role.COMPTABLE)
  getAlerts() {
    return this.service.getActiveAlerts();
  }
}
