import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export interface QueueEvent {
  event: string;
  timestamp: number;
  data: Record<string, any>;
  retries?: number;
}

@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);
  private redis: Redis;
  private readonly config: any;

  constructor(private configService: ConfigService) {
    this.config = this.configService.get('queue');
    this.initRedis();
  }

  private initRedis() {
    this.redis = new Redis(this.config.redis);
    this.redis.on('error', (err) => {
      this.logger.error('Redis connection error:', err);
    });
    this.redis.on('connect', () => {
      this.logger.log('Redis connected');
    });
  }

  /**
   * Queue a notification event for persistent delivery
   */
  async queueNotification(
    userId: string,
    event: Omit<QueueEvent, 'timestamp' | 'retries'>,
  ): Promise<void> {
    const queueKey = `queue:notification:${userId}`;
    const eventData: QueueEvent = {
      ...event,
      timestamp: Date.now(),
      retries: 0,
    };

    try {
      // LPUSH to queue (right side = most recent)
      const result = await this.redis
        .multi()
        .lpush(queueKey, JSON.stringify(eventData))
        .expire(queueKey, this.config.notification.ttlSeconds)
        .exec();

      if (!result || result[0][0]) {
        throw new Error('Redis queue operation failed');
      }

      this.logger.debug(
        `Queued notification for user ${userId}: ${event.event}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to queue notification for user ${userId}:`,
        error,
      );
      throw error;
    }
  }

  /**
   * Retrieve pending notifications for a user
   */
  async getPendingNotifications(userId: string): Promise<QueueEvent[]> {
    const queueKey = `queue:notification:${userId}`;

    try {
      const events = await this.redis.lrange(queueKey, 0, -1);
      return events.map((e) => JSON.parse(e)).reverse(); // FIFO order
    } catch (error) {
      this.logger.error(
        `Failed to fetch pending notifications for ${userId}:`,
        error,
      );
      return [];
    }
  }

  /**
   * Mark notification as delivered (remove from queue)
   */
  async removeNotification(
    userId: string,
    eventTimestamp: number,
  ): Promise<void> {
    const queueKey = `queue:notification:${userId}`;

    try {
      const events = await this.redis.lrange(queueKey, 0, -1);
      const indexToRemove = events.findIndex(
        (e) => JSON.parse(e).timestamp === eventTimestamp,
      );

      if (indexToRemove >= 0) {
        await this.redis.lrem(queueKey, 1, events[indexToRemove]);
        this.logger.debug(
          `Removed notification for user ${userId} at ${eventTimestamp}`,
        );
      }
    } catch (error) {
      this.logger.error(
        `Failed to remove notification for ${userId}:`,
        error,
      );
    }
  }

  /**
   * Retry failed notification with exponential backoff
   */
  async retryNotification(
    userId: string,
    event: QueueEvent,
  ): Promise<boolean> {
    if (!event.retries) event.retries = 0;

    if (event.retries >= this.config.notification.maxRetries) {
      this.logger.warn(
        `Max retries reached for user ${userId}: ${event.event}`,
      );
      return false;
    }

    event.retries++;
    const delayMs =
      this.config.notification.retryDelayMs * Math.pow(2, event.retries - 1);

    try {
      // Re-queue with exponential backoff
      setTimeout(() => {
        this.queueNotification(userId, event);
      }, delayMs);

      return true;
    } catch (error) {
      this.logger.error(
        `Failed to retry notification for ${userId}:`,
        error,
      );
      return false;
    }
  }

  /**
   * Clean up expired queues
   */
  async cleanup(): Promise<void> {
    try {
      const pattern = 'queue:notification:*';
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
        this.logger.debug(`Cleaned up ${keys.length} expired queues`);
      }
    } catch (error) {
      this.logger.error('Failed to cleanup queues:', error);
    }
  }

  async onModuleDestroy() {
    await this.redis.quit();
  }
}
