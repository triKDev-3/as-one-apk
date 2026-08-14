import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateIncidentDto } from './dto/create-incident.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { Role } from '@prisma/client';

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
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
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
