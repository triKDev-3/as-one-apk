import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { MaterialService } from './material.service';
import { CreateMaterialItemDto, UpdateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
import { CreateVehicleAlertDto } from './dto/create-alert.dto';
import {
  ApplySanctionDto,
  CheckReturnDto,
  CreateMaterialFicheDto,
  UpdateMaterialFicheDto,
} from './dto/fiche.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('material')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MaterialController {
  constructor(private readonly service: MaterialService) {}

  @Post('items/seed')
  @Roles(Role.ADMIN, Role.MAGASINIER)
  seedCatalog() {
    return this.service.ensureDefaultCatalog();
  }

  @Post('items')
  @Roles(Role.ADMIN, Role.MAGASINIER)
  createItem(@Body() dto: CreateMaterialItemDto) {
    return this.service.createItem(dto);
  }

  @Patch('items/:id')
  @Roles(Role.ADMIN, Role.MAGASINIER)
  updateItem(@Param('id') id: string, @Body() dto: UpdateMaterialItemDto) {
    return this.service.updateItem(id, dto);
  }

  @Get('items')
  @Roles(Role.ADMIN, Role.MAGASINIER, Role.CHEF)
  listItems(
    @Query('category') category?: string,
    @Query('all') all?: string,
  ) {
    return this.service.listItems(category, all === 'true');
  }

  @Post('fiches')
  @Roles(Role.CHEF, Role.MAGASINIER, Role.ADMIN)
  createFiche(@Body() dto: CreateMaterialFicheDto, @Request() req: any) {
    return this.service.createFiche(dto, req.user.id, req.user.role);
  }

  @Get('fiches')
  @Roles(Role.CHEF, Role.MAGASINIER, Role.ADMIN, Role.COMPTABLE)
  listFiches(
    @Query('siteId') siteId?: string,
    @Query('status') status?: string,
    @Request() req?: any,
  ) {
    return this.service.listFiches({
      siteId,
      status,
      userId: req.user.id,
      role: req.user.role,
    });
  }

  @Get('fiches/:id')
  @Roles(Role.CHEF, Role.MAGASINIER, Role.ADMIN, Role.COMPTABLE)
  getFiche(@Param('id') id: string) {
    return this.service.getFiche(id);
  }

  @Patch('fiches/:id')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  updateFiche(
    @Param('id') id: string,
    @Body() dto: UpdateMaterialFicheDto,
    @Request() req: any,
  ) {
    return this.service.updateFiche(id, dto, req.user.id);
  }

  @Post('fiches/:id/deliver')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  deliver(@Param('id') id: string, @Request() req: any) {
    return this.service.deliverFiche(id, req.user.id);
  }

  @Post('fiches/:id/return')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  checkReturn(
    @Param('id') id: string,
    @Body() dto: CheckReturnDto,
    @Request() req: any,
  ) {
    return this.service.checkReturn(id, dto, req.user.id);
  }

  @Post('fiches/:id/close')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  close(@Param('id') id: string, @Request() req: any) {
    return this.service.closeFiche(id, req.user.id);
  }

  @Get('damages')
  @Roles(Role.ADMIN, Role.MAGASINIER, Role.COMPTABLE)
  damages() {
    return this.service.listDamages();
  }

  @Post('sanctions')
  @Roles(Role.ADMIN)
  sanction(@Body() dto: ApplySanctionDto, @Request() req: any) {
    return this.service.applySanction(dto, req.user.id);
  }

  @Post('out')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  materialOut(@Body() dto: MaterialOutDto, @Request() req: any) {
    return this.service.materialOut(dto, req.user.id);
  }

  @Post('return')
  @Roles(Role.MAGASINIER, Role.ADMIN)
  materialReturn(@Body() dto: MaterialReturnDto, @Request() req: any) {
    return this.service.materialReturn(dto, req.user.id);
  }

  @Get('site/:siteId')
  @Roles(Role.MAGASINIER, Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getBySite(@Param('siteId') siteId: string) {
    return this.service.getMovementsBySite(siteId);
  }

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
