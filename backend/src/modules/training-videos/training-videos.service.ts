import { Injectable } from '@nestjs/common';
import { CreateTrainingVideoDto } from './dto/create-training-video.dto';
import { UpdateTrainingVideoDto } from './dto/update-training-video.dto';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class TrainingVideosService {
  constructor(private readonly prisma: PrismaService) {}

  create(createTrainingVideoDto: CreateTrainingVideoDto) {
    return this.prisma.trainingVideo.create({
      data: createTrainingVideoDto,
    });
  }

  findAll(activeOnly: boolean = false) {
    return this.prisma.trainingVideo.findMany({
      where: activeOnly ? { isActive: true } : undefined,
      orderBy: { orderIndex: 'asc' },
    });
  }

  findOne(id: string) {
    return this.prisma.trainingVideo.findUnique({
      where: { id },
    });
  }

  update(id: string, updateTrainingVideoDto: UpdateTrainingVideoDto) {
    return this.prisma.trainingVideo.update({
      where: { id },
      data: updateTrainingVideoDto,
    });
  }

  remove(id: string) {
    return this.prisma.trainingVideo.delete({
      where: { id },
    });
  }
}
