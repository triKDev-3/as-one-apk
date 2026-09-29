import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { SitesService } from './sites.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteDto } from './dto/update-site.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('sites')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SitesController {
  constructor(private readonly sitesService: SitesService) {}

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() dto: CreateSiteDto, @Request() req: any) {
    return this.sitesService.create(dto, req.user.id);
  }

  @Get()
  @Roles(Role.ADMIN, Role.CHEF, Role.COMPTABLE, Role.MAGASINIER)
  findAll(
    @Request() req: any,
    @Query('type') type?: string,
    @Query('all') all?: string,
  ) {
    return this.sitesService.findAll(
      type,
      req.user.id,
      req.user.role,
      all === 'true',
    );
  }

  @Get(':id')
  @Roles(Role.ADMIN, Role.CHEF, Role.COMPTABLE, Role.MAGASINIER)
  findOne(@Param('id') id: string) {
    return this.sitesService.findOne(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateSiteDto) {
    return this.sitesService.update(id, dto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  remove(@Param('id') id: string) {
    return this.sitesService.softDelete(id);
  }

  @Post(':id/chefs/:chefId')
  @Roles(Role.ADMIN)
  assignChef(@Param('id') siteId: string, @Param('chefId') chefId: string) {
    return this.sitesService.assignChef(siteId, chefId);
  }

  @Delete(':id/chefs/:chefId')
  @Roles(Role.ADMIN)
  removeChef(@Param('id') siteId: string, @Param('chefId') chefId: string) {
    return this.sitesService.removeChef(siteId, chefId);
  }

  /** Transfert de site entre chefs */
  @Post(':id/transfer')
  @Roles(Role.CHEF, Role.ADMIN)
  transfer(
    @Param('id') siteId: string,
    @Body() body: { toChefId: string; keepSelf?: boolean },
    @Request() req: any,
  ) {
    return this.sitesService.transferSite(
      siteId,
      body.toChefId,
      req.user.id,
      req.user.role,
      body.keepSelf === true,
    );
  }
}
