import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ReportsService } from './reports.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { CloseReportDto } from './dto/close-report.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class ReportsController {
  constructor(private readonly service: ReportsService) {}

  // --- Tâches journalières ---
  @Post('sites/:siteId/tasks')
  @Roles(Role.CHEF, Role.ADMIN)
  addTask(
    @Param('siteId') siteId: string,
    @Body() dto: CreateTaskDto,
    @Request() req: any,
  ) {
    return this.service.addTask(siteId, dto, req.user.id);
  }

  @Get('sites/:siteId/tasks')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  listTasks(@Param('siteId') siteId: string) {
    return this.service.listTasks(siteId);
  }

  // --- Rapport de fin de chantier ---
  @Post('sites/:siteId/close-report')
  @Roles(Role.CHEF, Role.ADMIN)
  closeReport(
    @Param('siteId') siteId: string,
    @Body() dto: CloseReportDto,
    @Request() req: any,
  ) {
    return this.service.closeAndGenerateReport(siteId, dto, req.user.id);
  }

  @Get('sites/:siteId/reports')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  listBySite(@Param('siteId') siteId: string) {
    return this.service.listReportsBySite(siteId);
  }

  @Get('reports')
  @Roles(Role.ADMIN, Role.COMPTABLE, Role.CHEF)
  listAll() {
    return this.service.listAllReports();
  }

  @Get('reports/:id')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getOne(@Param('id') id: string) {
    return this.service.getReport(id);
  }

  @Get('sites/:siteId/reports/latest')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getLatest(@Param('siteId') siteId: string) {
    return this.service.getLatestReportBySite(siteId);
  }

  @Patch('reports/:id')
  @Roles(Role.CHEF, Role.ADMIN)
  updateSummary(
    @Param('id') id: string,
    @Body('summary') summary: string,
  ) {
    return this.service.updateReportSummary(id, summary);
  }
}
