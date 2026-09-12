import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../modules/prisma/prisma.service';

@Injectable()
export class AssignmentValidator {
  constructor(private prisma: PrismaService) {}

  /**
   * Business rule: Agent cannot refuse affectation less than 22 hours before start
   */
  async validateRefusalTiming(assignmentId: string): Promise<void> {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment) {
      throw new BadRequestException('Assignment not found');
    }

    const hoursUntilStart =
      (assignment.startDate.getTime() - Date.now()) / (1000 * 60 * 60);

    if (hoursUntilStart < 22) {
      throw new BadRequestException(
        `Cannot refuse affectation less than 22 hours before start (${Math.floor(hoursUntilStart)} hours remaining)`,
      );
    }
  }

  /**
   * Business rule: Assignment must not be locked for modifications
   */
  async validateNotLocked(assignmentId: string): Promise<void> {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment) {
      throw new BadRequestException('Assignment not found');
    }

    if (assignment.isLocked) {
      throw new BadRequestException(
        'Assignment is locked and cannot be modified',
      );
    }
  }

  /**
   * Business rule: Only pending assignments can be confirmed/refused
   */
  async validatePendingStatus(assignmentId: string): Promise<void> {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: assignmentId },
    });

    if (!assignment) {
      throw new BadRequestException('Assignment not found');
    }

    if (assignment.status !== 'PENDING_CONFIRMATION') {
      throw new BadRequestException(
        `Assignment status is ${assignment.status}, cannot confirm/refuse`,
      );
    }
  }

  /**
   * Business rule: Agent availability must be checked
   */
  async validateAgentAvailability(agentId: string): Promise<void> {
    const agent = await this.prisma.agentProfile.findUnique({
      where: { userId: agentId },
    });

    if (!agent || !agent.isAvailable) {
      throw new BadRequestException('Agent is not available');
    }
  }
}
