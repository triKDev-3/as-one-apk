import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { PointageType, AssignmentStatus } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';

@Injectable()
export class PointageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
  ) {}

  /**
   * Pointage individuel ou en lot (fin de journée).
   * Anti-fraude basique : pas de double pointage ARRIVEE le même jour pour le même agent/site.
   */
  async create(dto: CreatePointageDto, createdById: string) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');

    const results = [];

    for (const agentId of dto.agentIds) {
      // Vérifier double pointage ARRIVEE le même jour
      if (dto.type === PointageType.ARRIVEE || dto.type === PointageType.PRESENCE_PERMANENCE) {
        const startOfDay = new Date();
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date();
        endOfDay.setHours(23, 59, 59, 999);

        const existing = await this.prisma.pointage.findFirst({
          where: {
            agentId,
            siteId: dto.siteId,
            type: dto.type,
            notedAt: { gte: startOfDay, lte: endOfDay },
          },
        });

        if (existing) {
          results.push({
            agentId,
            status: 'skipped',
            reason: 'Déjà pointé aujourd\'hui sur ce site',
          });
          continue;
        }
      }

      // Lier à une assignment si possible
      const assignment = await this.prisma.assignment.findFirst({
        where: {
          agentId,
          siteId: dto.siteId,
          status: {
            in: [
              AssignmentStatus.CONFIRMED,
              AssignmentStatus.LOCKED,
              AssignmentStatus.PENDING_CONFIRMATION,
            ],
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const pointage = await this.prisma.pointage.create({
        data: {
          siteId: dto.siteId,
          agentId,
          assignmentId: assignment?.id ?? null,
          type: dto.type,
          photoUrl: dto.photoUrl,
          latitude: dto.latitude,
          longitude: dto.longitude,
          createdById,
        },
        include: {
          agent: {
            select: { id: true, firstName: true, lastName: true, phone: true },
          },
        },
      });

      results.push({ agentId, status: 'ok', pointage });
      this.notifications.notifyPointage(agentId, {
        siteId: dto.siteId,
        type: dto.type,
        message: 'Votre pointage a été enregistré',
      });
    }

    return {
      siteId: dto.siteId,
      type: dto.type,
      results,
      successCount: results.filter((r) => r.status === 'ok').length,
      skippedCount: results.filter((r) => r.status === 'skipped').length,
    };
  }

  async getBySite(siteId: string, date?: string) {
    const where: any = { siteId };

    if (date) {
      const start = new Date(date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setHours(23, 59, 59, 999);
      where.notedAt = { gte: start, lte: end };
    }

    return this.prisma.pointage.findMany({
      where,
      include: {
        agent: {
          select: { id: true, firstName: true, lastName: true, phone: true },
        },
      },
      orderBy: { notedAt: 'desc' },
    });
  }

  async getByAgent(agentId: string, limit = 30) {
    return this.prisma.pointage.findMany({
      where: { agentId },
      include: {
        site: { select: { id: true, name: true, type: true } },
      },
      orderBy: { notedAt: 'desc' },
      take: limit,
    });
  }
}
