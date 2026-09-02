import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { SitesService } from './sites.service';
import { CreateSiteDto } from './dto/create-site.dto';
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
}
