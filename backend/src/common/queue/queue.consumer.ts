import { Injectable, Logger } from '@nestjs/common';
import { QueueService, QueueEvent } from './queue.service';
import { NotificationService } from '../../modules/notifications/notification.service';

@Injectable()
export class QueueConsumer {
  private readonly logger = new Logger(QueueConsumer.name);
  private isRunning = false;

  constructor(
    private queueService: QueueService,
    private notificationService: NotificationService,
  ) {}

  /**
   * Start consuming notifications from queue
   * Runs in background with configurable interval
   */
  async startConsumer(intervalMs = 5000): Promise<void> {
    if (this.isRunning) {
      this.logger.warn('Consumer already running');
      return;
    }

    this.isRunning = true;
    this.logger.log('Queue consumer started');

    const consume = async () => {
      try {
        // Get all active users with pending notifications
        const pendingKeys = await this.getPendingUserKeys();

        for (const userKey of pendingKeys) {
          const userId = userKey.replace('queue:notification:', '');
          await this.processUserQueue(userId);
        }
      } catch (error) {
        this.logger.error('Error in queue consumer loop:', error);
      }

      if (this.isRunning) {
        setTimeout(consume, intervalMs);
      }
    };

    consume();
  }

  /**
   * Stop the consumer
   */
  stopConsumer(): void {
    this.isRunning = false;
    this.logger.log('Queue consumer stopped');
  }

  /**
   * Process all pending notifications for a specific user
   */
  private async processUserQueue(userId: string): Promise<void> {
    const pendingEvents = await this.queueService.getPendingNotifications(
      userId,
    );

    for (const event of pendingEvents) {
      try {
        // Try to send via Socket.io first
        const delivered = await this.notificationService.sendViaSocket(
          userId,
          event,
        );

        if (delivered) {
          // Mark as delivered
          await this.queueService.removeNotification(userId, event.timestamp);
          this.logger.debug(
            `Delivered notification to ${userId}: ${event.event}`,
          );
        } else {
          // Save to AppNotification (DB) for later retrieval
          await this.notificationService.createAppNotification(
            userId,
            event,
          );
          await this.queueService.removeNotification(userId, event.timestamp);
        }
      } catch (error) {
        this.logger.error(
          `Failed to process notification for ${userId}:`,
          error,
        );
        // Retry with backoff
        const retried = await this.queueService.retryNotification(
          userId,
          event,
        );
        if (!retried) {
          // Max retries exceeded - save as failed in DB
          await this.notificationService.createAppNotification(
            userId,
            event,
            { status: 'FAILED', error: error.message },
          );
          await this.queueService.removeNotification(userId, event.timestamp);
        }
      }
    }
  }

  /**
   * Get all user IDs with pending notifications
   */
  private async getPendingUserKeys(): Promise<string[]> {
    // This would be implemented based on your Redis client
    // For now, return empty array - implement via queue service
    return [];
  }
}
