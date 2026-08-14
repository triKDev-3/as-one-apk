import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { PointageService } from './pointage.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('pointages')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PointageController {
  constructor(private readonly service: PointageService) {}

  @Post()
  @Roles(Role.CHEF, Role.ADMIN)
  create(@Body() dto: CreatePointageDto, @Request() req: any) {
    return this.service.create(dto, req.user.id);
  }

  @Get('site/:siteId')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getBySite(
    @Param('siteId') siteId: string,
    @Query('date') date?: string,
  ) {
    return this.service.getBySite(siteId, date);
  }

  @Get('me')
  @Roles(Role.AGENT)
  getMyPointages(@Request() req: any) {
    return this.service.getByAgent(req.user.id);
  }
}
