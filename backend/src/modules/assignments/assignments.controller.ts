import { Controller, Get, Post, Body, Param, Patch, UseGuards, Request } from '@nestjs/common';
import { AssignmentsService } from './assignments.service';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { RespondAssignmentDto } from './dto/respond-assignment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('assignments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AssignmentsController {
  constructor(private readonly service: AssignmentsService) {}

  @Post()
  @Roles(Role.CHEF, Role.ADMIN)
  create(@Body() dto: CreateAssignmentDto, @Request() req: any) {
    return this.service.create(dto, req.user.id);
  }

  @Get('transfers/pending')
  @Roles(Role.CHEF, Role.ADMIN)
  pendingTransfers(@Request() req: any) {
    return this.service.listPendingTransfers(req.user.id);
  }

  @Get('chefs')
  @Roles(Role.CHEF, Role.ADMIN)
  listChefs() {
    return this.service.listChefs();
  }

  @Get('site/:siteId')
  @Roles(Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  getBySite(@Param('siteId') siteId: string) {
    return this.service.getBySite(siteId);
  }

  @Patch('transfers/:id/resolve')
  @Roles(Role.CHEF, Role.ADMIN)
  resolveTransfer(
    @Param('id') id: string,
    @Body('accept') accept: boolean,
    @Request() req: any,
  ) {
    return this.service.resolveTransfer(id, req.user.id, accept);
  }

  @Patch(':id/respond')
  @Roles(Role.AGENT)
  respond(
    @Param('id') id: string,
    @Body() dto: RespondAssignmentDto,
    @Request() req: any,
  ) {
    return this.service.confirmOrRefuse(id, req.user.id, dto.accept);
  }

  @Post(':id/transfer')
  @Roles(Role.CHEF)
  requestTransfer(
    @Param('id') id: string,
    @Body('toChefId') toChefId: string,
    @Request() req: any,
  ) {
    return this.service.requestTransfer(id, req.user.id, toChefId);
  }
}
