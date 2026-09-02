import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class StatsService {
  constructor(private readonly prisma: PrismaService) {}

  async getLiveStats(userId: string, role: string, all: boolean) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};

    const [
      totalAgents,
      availableAgents,
      totalChefs,
      activeSites,
      todayPointages,
      openIncidents,
      pendingAssignments,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: 'AGENT', isActive: true } }),
      this.prisma.agentProfile.count({
        where: { isAvailable: true, user: { isActive: true } },
      }),
      this.prisma.user.count({ where: { role: 'CHEF', isActive: true } }),
      this.prisma.site.count({ where: { isActive: true, ...siteFilter } }),
      this.prisma.pointage.count({
        where: {
          notedAt: { gte: today, lt: tomorrow },
          ...(isFiltered ? { site: siteFilter } : {}),
        },
      }),
      this.prisma.incident.count({
        where: {
          status: 'OUVERT',
          ...(isFiltered ? { site: siteFilter } : {}),
        },
      }),
      this.prisma.assignment.count({
        where: {
          status: 'PENDING_CONFIRMATION',
          ...(isFiltered ? { site: siteFilter } : {}),
        },
      }),
    ]);

    return {
      totalAgents,
      availableAgents,
      busyAgents: totalAgents - availableAgents,
      totalChefs,
      activeSites,
      todayPointages,
      openIncidents,
      pendingAssignments,
      updatedAt: new Date().toISOString(),
    };
  }

  private async enrichWithStatus(userIds: string[]) {
    if (userIds.length === 0) return [];

    const activeAssignments = await this.prisma.assignment.findMany({
      where: {
        agentId: { in: userIds },
        status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
      },
      include: { site: { select: { id: true, name: true } } },
    });

    const profiles = await this.prisma.agentProfile.findMany({
      where: { userId: { in: userIds } },
      select: { userId: true, isAvailable: true },
    });

    const assignmentMap = new Map<string, string>();
    for (const a of activeAssignments) {
      assignmentMap.set(a.agentId, a.site?.name ?? 'Site inconnu');
    }

    const profileMap = new Map<string, boolean>();
    for (const p of profiles) {
      profileMap.set(p.userId, p.isAvailable);
    }

    return userIds.map((id) => {
      const currentSite = assignmentMap.get(id) ?? null;
      const isAvailable = profileMap.get(id) ?? true;
      let status: string;
      if (currentSite) status = 'SUR_CHANTIER';
      else if (!isAvailable) status = 'INDISPONIBLE';
      else status = 'DISPONIBLE';
      return { userId: id, currentSite, status };
    });
  }

  async getAgentsDetails(type: string, userId: string, role: string, all: boolean) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};

    let rawUsers: any[] = [];

    switch (type) {
      case 'total_agents':
        rawUsers = await this.prisma.user.findMany({
          where: { role: 'AGENT', isActive: true },
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
            agentType: true,
          },
        });
        break;
      case 'available_agents': {
        const availableProfiles = await this.prisma.agentProfile.findMany({
          where: { isAvailable: true, user: { isActive: true } },
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
              },
            },
          },
        });
        rawUsers = availableProfiles.map((p) => p.user);
        break;
      }
      case 'busy_agents': {
        const busyProfiles = await this.prisma.agentProfile.findMany({
          where: { isAvailable: false, user: { isActive: true } },
          include: {
            user: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
              },
            },
          },
        });
        rawUsers = busyProfiles.map((p) => p.user);
        break;
      }
      case 'pending_assignments': {
        const assignments = await this.prisma.assignment.findMany({
          where: {
            status: 'PENDING_CONFIRMATION',
            ...(isFiltered ? { site: siteFilter } : {}),
          },
          include: {
            agent: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
              },
            },
          },
        });
        const uniqueAgentIds = new Set<string>();
        for (const a of assignments) {
          if (!uniqueAgentIds.has(a.agent.id)) {
            uniqueAgentIds.add(a.agent.id);
            rawUsers.push(a.agent);
          }
        }
        break;
      }
      case 'today_pointages': {
        const pointages = await this.prisma.pointage.findMany({
          where: {
            notedAt: { gte: today, lt: tomorrow },
            ...(isFiltered ? { site: siteFilter } : {}),
          },
          include: {
            agent: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
              },
            },
          },
        });
        const uniquePointageAgentIds = new Set<string>();
        for (const p of pointages) {
          if (!uniquePointageAgentIds.has(p.agent.id)) {
            uniquePointageAgentIds.add(p.agent.id);
            rawUsers.push(p.agent);
          }
        }
        break;
      }
      default:
        return [];
    }

    const userIds = rawUsers.map((u) => u.id);
    const enriched = await this.enrichWithStatus(userIds);
    const enrichedMap = new Map(enriched.map((e) => [e.userId, e]));

    return rawUsers.map((u) => ({
      ...u,
      status: enrichedMap.get(u.id)?.status ?? 'DISPONIBLE',
      currentSite: enrichedMap.get(u.id)?.currentSite ?? null,
    }));
  }

  async getAgentsBySite(userId: string, role: string, all: boolean) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};

    const sites = await this.prisma.site.findMany({
      where: { isActive: true, ...siteFilter },
      include: {
        assignments: {
          where: {
            status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
          },
          include: {
            agent: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                agentType: true,
              },
            },
          },
        },
      },
    });

    return sites.map((site) => ({
      id: site.id,
      name: site.name,
      type: site.type,
      agentCount: site.assignments.length,
      agents: site.assignments.map((a) => ({
        ...a.agent,
        status: 'SUR_CHANTIER',
        currentSite: site.name,
      })),
    }));
  }

  /**
   * Calendrier global chef / admin : agrège pointages, incidents, affectations par jour.
   */
  async getChefCalendar(
    userId: string,
    role: string,
    monthKey: string,
    all: boolean,
  ) {
    const [year, month] = monthKey.split('-').map(Number);
    const start = new Date(Date.UTC(year, month - 1, 1));
    const end = new Date(Date.UTC(year, month, 0, 23, 59, 59));

    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};

    const [pointages, incidents, assignments] = await Promise.all([
      this.prisma.pointage.findMany({
        where: {
          notedAt: { gte: start, lte: end },
          ...(isFiltered ? { site: siteFilter } : {}),
        },
        include: {
          site: { select: { id: true, name: true } },
          agent: { select: { firstName: true, lastName: true } },
        },
        orderBy: { notedAt: 'asc' },
      }),
      this.prisma.incident.findMany({
        where: {
          createdAt: { gte: start, lte: end },
          ...(isFiltered ? { site: siteFilter } : {}),
        },
        include: {
          site: { select: { id: true, name: true } },
        },
      }),
      this.prisma.assignment.findMany({
        where: {
          OR: [
            { startDate: { gte: start, lte: end } },
            {
              startDate: { lte: end },
              OR: [{ endDate: null }, { endDate: { gte: start } }],
            },
          ],
          status: {
            in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'],
          },
          ...(isFiltered ? { site: siteFilter } : {}),
        },
        include: {
          site: { select: { id: true, name: true } },
          agent: { select: { firstName: true, lastName: true } },
        },
      }),
    ]);

    type DayBucket = {
      pointages: number;
      absents: number;
      incidents: number;
      pending: number;
      events: Array<{
        kind: string;
        label: string;
        siteName?: string;
        siteId?: string;
      }>;
    };

    const days: Record<string, DayBucket> = {};

    const ensure = (key: string): DayBucket => {
      if (!days[key]) {
        days[key] = {
          pointages: 0,
          absents: 0,
          incidents: 0,
          pending: 0,
          events: [],
        };
      }
      return days[key];
    };

    for (const p of pointages) {
      const key = p.notedAt.toISOString().slice(0, 10);
      const b = ensure(key);
      if (p.type === 'ABSENT') b.absents += 1;
      else b.pointages += 1;
      b.events.push({
        kind: p.type === 'ABSENT' ? 'absent' : 'pointage',
        label: `${p.agent.firstName} ${p.agent.lastName} · ${p.type}`,
        siteName: p.site.name,
        siteId: p.site.id,
      });
    }

    for (const i of incidents) {
      const key = i.createdAt.toISOString().slice(0, 10);
      const b = ensure(key);
      b.incidents += 1;
      b.events.push({
        kind: 'incident',
        label: i.title || 'Incident',
        siteName: i.site?.name,
        siteId: i.site?.id,
      });
    }

    for (const a of assignments) {
      const aStart = new Date(a.startDate);
      aStart.setUTCHours(0, 0, 0, 0);
      const aEnd = a.endDate ? new Date(a.endDate) : aStart;
      aEnd.setUTCHours(23, 59, 59, 999);

      const cursor = new Date(Math.max(aStart.getTime(), start.getTime()));
      const limit = new Date(Math.min(aEnd.getTime(), end.getTime()));

      while (cursor <= limit) {
        if (cursor.getUTCDay() !== 0) {
          const key = cursor.toISOString().slice(0, 10);
          const b = ensure(key);
          if (a.status === 'PENDING_CONFIRMATION') b.pending += 1;
          b.events.push({
            kind:
              a.status === 'PENDING_CONFIRMATION'
                ? 'assignment_pending'
                : 'assignment',
            label: `${a.agent.firstName} ${a.agent.lastName}`,
            siteName: a.site.name,
            siteId: a.site.id,
          });
        }
        cursor.setUTCDate(cursor.getUTCDate() + 1);
      }
    }

    // Résumé compact pour les pastilles du calendrier
    const summary: Record<
      string,
      {
        pointages: number;
        absents: number;
        incidents: number;
        pending: number;
        hasActivity: boolean;
      }
    > = {};

    for (const [key, b] of Object.entries(days)) {
      summary[key] = {
        pointages: b.pointages,
        absents: b.absents,
        incidents: b.incidents,
        pending: b.pending,
        hasActivity:
          b.pointages + b.absents + b.incidents + b.pending + b.events.length > 0,
      };
    }

    return { month: monthKey, summary, days };
  }
}
