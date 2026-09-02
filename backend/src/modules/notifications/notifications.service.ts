import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsGateway } from './notifications.gateway';
import { Prisma } from '@prisma/client';

export type PushInput = {
  title: string;
  body: string;
  type: string;
  data?: Record<string, unknown>;
};

@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gateway: NotificationsGateway,
  ) {}

  async push(userId: string, input: PushInput) {
    const row = await this.prisma.appNotification.create({
      data: {
        userId,
        title: input.title,
        body: input.body,
        type: input.type,
        data: (input.data ?? undefined) as Prisma.InputJsonValue | undefined,
      },
    });

    const payload = {
      id: row.id,
      title: input.title,
      body: input.body,
      type: input.type,
      data: input.data ?? {},
      createdAt: row.createdAt,
    };

    this.gateway.notifyUser(userId, 'notification', payload);
    this.gateway.notifyUser(userId, input.type, {
      message: input.body,
      title: input.title,
      ...(input.data || {}),
    });
    return row;
  }

  async pushMany(userIds: string[], input: PushInput) {
    const unique = [...new Set(userIds.filter(Boolean))];
    await Promise.all(unique.map((id) => this.push(id, input)));
  }

  async list(userId: string, limit = 80) {
    return this.prisma.appNotification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async markRead(id: string, userId: string) {
    return this.prisma.appNotification.updateMany({
      where: { id, userId, readAt: null },
      data: { readAt: new Date() },
    });
  }

  async markAllRead(userId: string) {
    return this.prisma.appNotification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
  }

  async unreadCount(userId: string) {
    return this.prisma.appNotification.count({
      where: { userId, readAt: null },
    });
  }
}
