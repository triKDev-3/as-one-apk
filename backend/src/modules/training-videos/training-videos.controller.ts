import { Controller, Get, Post, Body, Patch, Param, Delete, Query, UseGuards } from '@nestjs/common';
import { TrainingVideosService } from './training-videos.service';
import { CreateTrainingVideoDto } from './dto/create-training-video.dto';
import { UpdateTrainingVideoDto } from './dto/update-training-video.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller('training-videos')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TrainingVideosController {
  constructor(private readonly trainingVideosService: TrainingVideosService) {}

  @Post()
  @Roles(Role.ADMIN)
  create(@Body() createTrainingVideoDto: CreateTrainingVideoDto) {
    return this.trainingVideosService.create(createTrainingVideoDto);
  }

  @Get()
  @Roles(Role.ADMIN, Role.AGENT, Role.CHEF, Role.MAGASINIER)
  findAll(@Query('activeOnly') activeOnly?: string) {
    return this.trainingVideosService.findAll(activeOnly === 'true');
  }

  @Get(':id')
  @Roles(Role.ADMIN, Role.AGENT, Role.CHEF, Role.MAGASINIER)
  findOne(@Param('id') id: string) {
    return this.trainingVideosService.findOne(id);
  }

  @Patch(':id')
  @Roles(Role.ADMIN)
  update(@Param('id') id: string, @Body() updateTrainingVideoDto: UpdateTrainingVideoDto) {
    return this.trainingVideosService.update(id, updateTrainingVideoDto);
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  remove(@Param('id') id: string) {
    return this.trainingVideosService.remove(id);
  }
}
