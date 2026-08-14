import { Controller, Get, Post, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { RatingService } from './rating.service';
import { CreateRatingDto } from './dto/create-rating.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('ratings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RatingController {
  constructor(private readonly service: RatingService) {}

  @Post()
  @Roles(Role.CHEF, Role.ADMIN)
  create(@Body() dto: CreateRatingDto, @Request() req: any) {
    return this.service.create(dto, req.user.id);
  }

  @Get('ranking')
  @Roles(Role.AGENT, Role.CHEF, Role.ADMIN, Role.COMPTABLE)
  ranking(@Query('limit') limit?: string) {
    return this.service.getRanking(limit ? parseInt(limit, 10) : 50);
  }

  @Get('assignment/:assignmentId')
  @Roles(Role.CHEF, Role.ADMIN)
  byAssignment(@Param('assignmentId') assignmentId: string) {
    return this.service.getByAssignment(assignmentId);
  }
}
