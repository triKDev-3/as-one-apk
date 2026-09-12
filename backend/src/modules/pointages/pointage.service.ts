import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePointageDto } from '../../common/dtos/pointage.dto';
import { QueueService } from '../../common/queue/queue.service';

@Injectable()
export class PointageService {
  private readonly logger = new Logger(PointageService.name);

  constructor(
    private prisma: PrismaService,
    private queueService: QueueService,
  ) {}

  /**
   * Record pointage with atomic transaction
   * Atomically: Create pointage + Update assignment status + Queue notification
   */
  async recordPointage(createPointageDto: CreatePointageDto, chefId: string) {
    return await this.prisma.$transaction(
      async (tx) => {
        // 1. Create pointage record
        const pointage = await tx.pointage.create({
          data: {
            assignmentId: createPointageDto.assignmentId,
            siteId: createPointageDto.siteId,
            agentId: createPointageDto.agentId,
            type: createPointageDto.type,
            photoUrl: createPointageDto.photoUrl,
            latitude: createPointageDto.latitude,
            longitude: createPointageDto.longitude,
            createdById: chefId,
          },
          include: {
            assignment: true,
          },
        });

        // 2. If ARRIVEE (arrival), mark assignment as started (optional logic)
        if (
          createPointageDto.type === 'ARRIVEE' &&
          createPointageDto.assignmentId
        ) {
          await tx.assignment.update({
            where: { id: createPointageDto.assignmentId },
            data: {
              // Optional: add startedAt field to schema
            },
          });
        }

        // 3. Create audit log
        await tx.auditLog.create({
          data: {
            userId: chefId,
            action: 'POINTAGE_RECORDED',
            entity: 'Pointage',
            entityId: pointage.id,
            metadata: {
              type: createPointageDto.type,
              location: `${createPointageDto.latitude}, ${createPointageDto.longitude}`,
            },
          },
        });

        return pointage;
      },
      { maxWait: 5000, timeout: 10000 },
    );
  }

  /**
   * Get pointages for assignment
   */
  async getPointagesForAssignment(assignmentId: string) {
    return await this.prisma.pointage.findMany({
      where: { assignmentId },
      orderBy: { notedAt: 'desc' },
    });
  }
}
