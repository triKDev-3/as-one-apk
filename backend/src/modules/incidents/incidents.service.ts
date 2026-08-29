import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { Role, RetentionTarget, AssignmentStatus } from '@prisma/client';
import { ApplyPenaltyDto } from './dto/apply-penalty.dto';

@Injectable()
export class IncidentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsGateway,
  ) {}

  async create(dto: CreateIncidentDto, reportedById: string) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');

    const incident = await this.prisma.incident.create({
      data: {
        siteId: dto.siteId,
        reportedById,
        description: dto.description,
        photoUrl: dto.photoUrl,
        type: dto.type || 'AUTRE',
        severity: dto.severity || 'MOYENNE',
      },
      include: {
        site: { select: { id: true, name: true } },
        reportedBy: {
          select: { id: true, firstName: true, lastName: true, role: true },
        },
      },
    });

    // Notifier les admins (broadcast room simplifié via users admin)
    const admins = await this.prisma.user.findMany({
      where: { role: Role.ADMIN, isActive: true },
      select: { id: true },
    });
    for (const admin of admins) {
      this.notifications.notifyUser(admin.id, 'incident:new', {
        id: incident.id,
        site: incident.site,
        type: incident.type,
        severity: incident.severity,
        message: `Incident signalé sur ${incident.site.name}`,
      });
    }

    return incident;
  }

  async list(filters?: { siteId?: string; status?: string }) {
    return this.prisma.incident.findMany({
      where: {
        ...(filters?.siteId ? { siteId: filters.siteId } : {}),
        ...(filters?.status ? { status: filters.status } : {}),
      },
      include: {
        site: { select: { id: true, name: true, type: true } },
        reportedBy: {
          select: { id: true, firstName: true, lastName: true, role: true },
        },
        penalties: {
          include: {
            agent: { select: { id: true, firstName: true, lastName: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async applyPenalty(incidentId: string, dto: ApplyPenaltyDto, appliedById: string) {
    const incident = await this.prisma.incident.findUnique({ where: { id: incidentId } });
    if (!incident) throw new NotFoundException('Incident introuvable');

    if (dto.target === RetentionTarget.ONE_AGENT) {
      if (!dto.agentId) throw new BadRequestException('agentId obligatoire');
      return this.prisma.incidentPenalty.create({
        data: {
          incidentId,
          agentId: dto.agentId,
          target: RetentionTarget.ONE_AGENT,
          amount: dto.amount,
          reason: dto.reason,
          appliedById,
        },
        include: {
          agent: { select: { id: true, firstName: true, lastName: true } },
        },
      });
    }

    const assignments = await this.prisma.assignment.findMany({
      where: {
        siteId: incident.siteId,
        status: { in: [AssignmentStatus.CONFIRMED, AssignmentStatus.LOCKED] },
      },
      select: { agentId: true },
    });
    const ids = [...new Set(assignments.map((a) => a.agentId))];
    if (ids.length === 0) {
      throw new BadRequestException('Aucun agent affecté sur ce site pour répartir la pénalité');
    }
    const share = Math.round((dto.amount / ids.length) * 100) / 100;
    await this.prisma.incidentPenalty.createMany({
      data: ids.map((agentId) => ({
        incidentId,
        agentId,
        target: RetentionTarget.WHOLE_GROUP,
        amount: share,
        reason: dto.reason,
        appliedById,
      })),
    });
    return { ok: true, agents: ids.length, amountEach: share };
  }

  async resolve(id: string, userId: string, role: Role) {
    if (role !== Role.ADMIN && role !== Role.CHEF) {
      throw new ForbiddenException();
    }
    const incident = await this.prisma.incident.findUnique({ where: { id } });
    if (!incident) throw new NotFoundException();

    return this.prisma.incident.update({
      where: { id },
      data: { status: 'RESOLU', resolvedAt: new Date() },
    });
  }
}
