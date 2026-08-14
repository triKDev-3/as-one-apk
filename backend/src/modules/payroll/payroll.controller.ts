import { Controller, Get, Post, Body, Param, Patch, UseGuards, Request } from '@nestjs/common';
import { PayrollService } from './payroll.service';
import { CreatePeriodDto } from './dto/create-period.dto';
import { AdjustLineDto } from './dto/adjust-line.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('payroll')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PayrollController {
  constructor(private readonly service: PayrollService) {}

  @Post('periods')
  @Roles(Role.COMPTABLE, Role.ADMIN)
  createPeriod(@Body() dto: CreatePeriodDto, @Request() req: any) {
    return this.service.createPeriod(dto, req.user.id);
  }

  @Get('periods')
  @Roles(Role.COMPTABLE, Role.ADMIN)
  listPeriods() {
    return this.service.listPeriods();
  }

  @Get('periods/:id')
  @Roles(Role.COMPTABLE, Role.ADMIN)
  getPeriod(@Param('id') id: string) {
    return this.service.getPeriod(id);
  }

  @Patch('lines/:id')
  @Roles(Role.COMPTABLE, Role.ADMIN)
  adjustLine(@Param('id') id: string, @Body() dto: AdjustLineDto) {
    return this.service.adjustLine(id, dto);
  }

  @Post('periods/:id/validate')
  @Roles(Role.ADMIN) // Direction valide définitivement
  validate(@Param('id') id: string) {
    return this.service.validatePeriod(id);
  }

  @Get('periods/:periodId/site/:siteId/virements')
  @Roles(Role.COMPTABLE, Role.CHEF, Role.ADMIN)
  virementList(
    @Param('periodId') periodId: string,
    @Param('siteId') siteId: string,
  ) {
    return this.service.getVirementListBySite(periodId, siteId);
  }
}
