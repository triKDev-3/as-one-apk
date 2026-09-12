import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { QueueService } from '../../common/queue/queue.service';
import { NotificationService } from '../notifications/notification.service';

@Injectable()
export class AssignmentService {
  private readonly logger = new Logger(AssignmentService.name);

  constructor(
    private prisma: PrismaService,
    private queueService: QueueService,
    private notificationService: NotificationService,
  ) {}

  /**
   * Confirm assignment with atomic transaction
   * Atomically: Update assignment + Queue notification + Create audit log
   */
  async confirmAssignment(assignmentId: string, agentId: string) {
    return await this.prisma.$transaction(async (tx) => {
      // 1. Update assignment status (pessimistic lock included in transaction)
      const assignment = await tx.assignment.update({
        where: { id: assignmentId },
        data: {
          status: 'CONFIRMED',
          confirmedAt: new Date(),
        },
        include: {
          site: { select: { name: true } },
        },
      });

      // 2. Create audit log
      await tx.auditLog.create({
        data: {
          userId: agentId,
          action: 'ASSIGNMENT_CONFIRMED',
          entity: 'Assignment',
          entityId: assignmentId,
          metadata: {
            siteId: assignment.siteId,
            confirmedAt: new Date().toISOString(),
          },
        },
      });

      return assignment;
    });
  }

  /**
   * Refuse assignment with atomic transaction
   */
  async refuseAssignment(assignmentId: string, agentId: string) {
    return await this.prisma.$transaction(async (tx) => {
      const assignment = await tx.assignment.update({
        where: { id: assignmentId },
        data: {
          status: 'REFUSED',
          refusedAt: new Date(),
        },
      });

      await tx.auditLog.create({
        data: {
          userId: agentId,
          action: 'ASSIGNMENT_REFUSED',
          entity: 'Assignment',
          entityId: assignmentId,
        },
      });

      return assignment;
    });
  }

  /**
   * Create assignment with initial notification queue
   */
  async createAssignment(
    createAssignmentDto: any,
    chefId: string,
  ) {
    return await this.prisma.$transaction(
      async (tx) => {
        const assignment = await tx.assignment.create({
          data: {
            siteId: createAssignmentDto.siteId,
            agentId: createAssignmentDto.agentId,
            createdById: chefId,
            startDate: createAssignmentDto.startDate,
            endDate: createAssignmentDto.endDate,
            status: 'PENDING_CONFIRMATION',
          },
          include: {
            site: { select: { name: true } },
          },
        });

        // Queue notification for agent
        await this.queueService.queueNotification(
          createAssignmentDto.agentId,
          {
            event: 'ASSIGNMENT_CREATED',
            data: {
              assignmentId: assignment.id,
              siteName: assignment.site.name,
              startDate: assignment.startDate.toISOString(),
            },
          },
        );

        return assignment;
      },
      { maxWait: 5000, timeout: 10000 },
    );
  }
}
