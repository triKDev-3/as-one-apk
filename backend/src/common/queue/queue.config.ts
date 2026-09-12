import { registerAs } from '@nestjs/config';

export const queueConfig = registerAs('queue', () => ({
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD,
    db: parseInt(process.env.REDIS_DB || '0', 10),
  },
  notification: {
    maxRetries: 3,
    retryDelayMs: 5000,
    ttlSeconds: 86400, // 24h
  },
}));
