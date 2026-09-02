import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { PointageType, AssignmentStatus } from '@prisma/client';
import { NotificationsGateway } from '../notifications/notifications.gateway';

function dayBoundsTogo(date = new Date()) {
  const key = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Africa/Lome',
  }).format(date);
  const start = new Date(`${key}T00:00:00+00:00`);
  const end = new Date(`${key}T23:59:59.999+00:00`);
  return { start, end, key };
}

@Injectable()
export class PointageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
  ) {}

  async create(dto: CreatePointageDto, createdById: string) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');

    const type = dto.type ?? PointageType.DEPART;
    const notedDate = dto.notedAt ? new Date(dto.notedAt) : new Date();
    const { start, end, key } = dayBoundsTogo(notedDate);
    const results = [];

    for (const agentId of dto.agentIds) {
      const existing = await this.prisma.pointage.findFirst({
        where: {
          agentId,
          siteId: dto.siteId,
          type,
          notedAt: { gte: start, lte: end },
        },
      });

      if (existing) {
        results.push({
          agentId,
          status: 'skipped',
          reason:
            type === PointageType.ABSENT
              ? `Déjà marqué absent le ${key}`
              : `Départ déjà enregistré le ${key}`,
        });
        continue;
      }

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

      if (assignment && assignment.status === AssignmentStatus.PENDING_CONFIRMATION) {
        await this.prisma.assignment.update({
          where: { id: assignment.id },
          data: { status: AssignmentStatus.CONFIRMED },
        });
      }

      const pointage = await this.prisma.pointage.create({
        data: {
          siteId: dto.siteId,
          agentId,
          assignmentId: assignment?.id ?? null,
          type,
          photoUrl: dto.photoUrl,
          latitude: dto.latitude,
          longitude: dto.longitude,
          createdById,
          notedAt: start,
        },
        include: {
          agent: {
            select: { id: true, firstName: true, lastName: true, phone: true },
          },
        },
      });

      results.push({ agentId, status: 'ok', pointage });

      const isPast = key !== dayBoundsTogo().key;
      const dateLabel = new Date(`${key}T12:00:00+00:00`).toLocaleDateString('fr-FR');
      this.notifications.notifyPointage(agentId, {
        siteId: dto.siteId,
        type,
        date: key,
        message:
          type === PointageType.ABSENT
            ? `Vous avez été marqué(e) absent(e) le ${dateLabel} sur ${site.name}`
            : isPast
              ? `Votre départ du ${dateLabel} a été enregistré sur ${site.name}`
              : `Votre départ a été enregistré sur ${site.name}`,
      });
    }

    return {
      siteId: dto.siteId,
      type,
      results,
      successCount: results.filter((r) => r.status === 'ok').length,
      skippedCount: results.filter((r) => r.status === 'skipped').length,
    };
  }

  async list(filters?: { siteId?: string; date?: string; type?: string }) {
    const where: Record<string, unknown> = {};
    if (filters?.siteId) where.siteId = filters.siteId;
    if (filters?.type) where.type = filters.type;
    if (filters?.date) {
      const { start, end } = dayBoundsTogo(new Date(filters.date));
      where.notedAt = { gte: start, lte: end };
    }

    return this.prisma.pointage.findMany({
      where,
      include: {
        agent: {
          select: { id: true, firstName: true, lastName: true, phone: true, role: true },
        },
        site: { select: { id: true, name: true, type: true } },
      },
      orderBy: { notedAt: 'desc' },
      take: 300,
    });
  }

  async getBySite(siteId: string, date?: string) {
    return this.list({ siteId, date });
  }

  async getByAgent(agentId: string, limit = 60) {
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
