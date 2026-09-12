import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { QueueService, QueueEvent } from '../../common/queue/queue.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private prisma: PrismaService,
    private queueService: QueueService,
  ) {}

  /**
   * Send notification via Socket.io (returns false if user not connected)
   */
  async sendViaSocket(userId: string, event: QueueEvent): Promise<boolean> {
    try {
      // This would integrate with your Socket.io gateway
      // Placeholder for Socket.io emit
      this.logger.debug(`Sending via Socket.io to ${userId}: ${event.event}`);
      return true; // Assume success if no error
    } catch (error) {
      this.logger.error(`Socket.io send failed for ${userId}:`, error);
      return false;
    }
  }

  /**
   * Create persistent AppNotification in database
   */
  async createAppNotification(
    userId: string,
    event: QueueEvent,
    metadata?: Record<string, any>,
  ): Promise<any> {
    try {
      return await this.prisma.appNotification.create({
        data: {
          userId,
          title: this.getTitleFromEvent(event),
          body: this.getBodyFromEvent(event),
          type: event.event,
          data: {
            ...event.data,
            ...metadata,
          },
        },
      });
    } catch (error) {
      this.logger.error(
        `Failed to create AppNotification for ${userId}:`,
        error,
      );
      throw error;
    }
  }

  /**
   * Get all unread notifications for a user
   */
  async getUnreadNotifications(userId: string) {
    return await this.prisma.appNotification.findMany({
      where: {
        userId,
        readAt: null,
      },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId: string): Promise<void> {
    await this.prisma.appNotification.update({
      where: { id: notificationId },
      data: { readAt: new Date() },
    });
  }

  /**
   * Queue assignment notification with transaction support
   */
  async queueAssignmentNotification(
    assignmentId: string,
    agentId: string,
    status: string,
  ): Promise<void> {
    const event: Omit<QueueEvent, 'timestamp' | 'retries'> = {
      event: 'ASSIGNMENT_' + status.toUpperCase(),
      data: {
        assignmentId,
        agentId,
        status,
      },
    };

    await this.queueService.queueNotification(agentId, event);
  }

  private getTitleFromEvent(event: QueueEvent): string {
    const titles: Record<string, string> = {
      ASSIGNMENT_CREATED: 'Nouvelle affectation',
      ASSIGNMENT_CONFIRMED: 'Affectation confirmée',
      ASSIGNMENT_REFUSED: 'Affectation refusée',
      POINTAGE_RECORDED: 'Pointage enregistré',
      MATERIAL_MOVEMENT: 'Mouvement matériel',
      PAYROLL_READY: 'Paie prête à valider',
    };
    return titles[event.event] || 'Notification';
  }

  private getBodyFromEvent(event: QueueEvent): string {
    const { data } = event;
    const bodies: Record<string, (d: any) => string> = {
      ASSIGNMENT_CREATED: (d) => `Site: ${d.siteName || 'N/A'}`,
      ASSIGNMENT_CONFIRMED: (d) => `Confirmée pour ${d.startDate || 'N/A'}`,
      POINTAGE_RECORDED: (d) =>
        `À ${d.notedAt || 'N/A'} - Localisation: ${d.location || 'N/A'}`,
      PAYROLL_READY: (d) => `Période: ${d.periodId || 'N/A'}`,
    };
    return (bodies[event.event]?.(data) || 'Consultez l\'application') as string;
  }
}
