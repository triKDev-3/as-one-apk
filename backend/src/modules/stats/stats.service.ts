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
      // Total agents actifs (Toujours global selon la décision)
      this.prisma.user.count({
        where: { role: 'AGENT', isActive: true },
      }),
      // Agents disponibles (Toujours global)
      this.prisma.agentProfile.count({
        where: { isAvailable: true, user: { isActive: true } },
      }),
      // Total chefs actifs (Toujours global)
      this.prisma.user.count({
        where: { role: 'CHEF', isActive: true },
      }),
      // Chantiers actifs (Filtré)
      this.prisma.site.count({
        where: { isActive: true, ...siteFilter },
      }),
      // Pointages du jour (Filtré)
      this.prisma.pointage.count({
        where: {
          notedAt: { gte: today, lt: tomorrow },
          ...(isFiltered ? { site: siteFilter } : {}),
        },
      }),
      // Incidents ouverts (Filtré)
      this.prisma.incident.count({
        where: {
          status: 'OUVERT',
          ...(isFiltered ? { site: siteFilter } : {}),
        },
      }),
      // Affectations en attente de confirmation (Filtré)
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

  /** Helper: enrich a user list with status + currentSite */
  private async enrichWithStatus(userIds: string[]) {
    if (userIds.length === 0) return [];

    // Fetch active assignments for these users
    const activeAssignments = await this.prisma.assignment.findMany({
      where: {
        agentId: { in: userIds },
        status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
      },
      include: { site: { select: { id: true, name: true } } },
    });

    // Fetch availability profiles
    const profiles = await this.prisma.agentProfile.findMany({
      where: { userId: { in: userIds } },
      select: { userId: true, isAvailable: true },
    });

    const assignmentMap = new Map<string, string>(); // userId -> siteName
    for (const a of activeAssignments) {
      assignmentMap.set(a.agentId, a.site?.name ?? 'Site inconnu');
    }

    const profileMap = new Map<string, boolean>(); // userId -> isAvailable
    for (const p of profiles) {
      profileMap.set(p.userId, p.isAvailable);
    }

    return userIds.map((id) => {
      const currentSite = assignmentMap.get(id) ?? null;
      const isAvailable = profileMap.get(id) ?? true;

      let status: string;
      if (currentSite) {
        status = 'SUR_CHANTIER';
      } else if (!isAvailable) {
        status = 'INDISPONIBLE';
      } else {
        status = 'DISPONIBLE';
      }

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
          select: { id: true, firstName: true, lastName: true, phone: true, agentType: true },
        });
        break;

      case 'available_agents':
        const availableProfiles = await this.prisma.agentProfile.findMany({
          where: { isAvailable: true, user: { isActive: true } },
          include: { user: { select: { id: true, firstName: true, lastName: true, phone: true, agentType: true } } },
        });
        rawUsers = availableProfiles.map(p => p.user);
        break;

      case 'busy_agents':
        const busyProfiles = await this.prisma.agentProfile.findMany({
          where: { isAvailable: false, user: { isActive: true } },
          include: { user: { select: { id: true, firstName: true, lastName: true, phone: true, agentType: true } } },
        });
        rawUsers = busyProfiles.map(p => p.user);
        break;

      case 'pending_assignments':
        const assignments = await this.prisma.assignment.findMany({
          where: {
            status: 'PENDING_CONFIRMATION',
            ...(isFiltered ? { site: siteFilter } : {}),
          },
          include: { agent: { select: { id: true, firstName: true, lastName: true, phone: true, agentType: true } } },
        });
        const uniqueAgentIds = new Set<string>();
        for (const a of assignments) {
          if (!uniqueAgentIds.has(a.agent.id)) {
            uniqueAgentIds.add(a.agent.id);
            rawUsers.push(a.agent);
          }
        }
        break;

      case 'today_pointages':
        const pointages = await this.prisma.pointage.findMany({
          where: {
            notedAt: { gte: today, lt: tomorrow },
            ...(isFiltered ? { site: siteFilter } : {}),
          },
          include: { agent: { select: { id: true, firstName: true, lastName: true, phone: true, agentType: true } } },
        });
        const uniquePointageAgentIds = new Set<string>();
        for (const p of pointages) {
          if (!uniquePointageAgentIds.has(p.agent.id)) {
            uniquePointageAgentIds.add(p.agent.id);
            rawUsers.push(p.agent);
          }
        }
        break;

      default:
        return [];
    }

    // Enrich with status/currentSite
    const userIds = rawUsers.map(u => u.id);
    const enriched = await this.enrichWithStatus(userIds);
    const enrichedMap = new Map(enriched.map(e => [e.userId, e]));

    return rawUsers.map(u => ({
      ...u,
      status: enrichedMap.get(u.id)?.status ?? 'DISPONIBLE',
      currentSite: enrichedMap.get(u.id)?.currentSite ?? null,
    }));
  }

  /** Get agents grouped by site for "Mes équipes" */
  async getAgentsBySite(userId: string, role: string, all: boolean) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered ? { chefs: { some: { chefId: userId } } } : {};

    const sites = await this.prisma.site.findMany({
      where: {
        isActive: true,
        ...siteFilter,
      },
      include: {
        assignments: {
          where: { status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] } },
          include: {
            agent: {
              select: { id: true, firstName: true, lastName: true, phone: true, agentType: true },
            },
          },
        },
      },
    });

    return sites.map(site => ({
      id: site.id,
      name: site.name,
      type: site.type,
      agentCount: site.assignments.length,
      agents: site.assignments.map(a => ({
        ...a.agent,
        status: 'SUR_CHANTIER',
        currentSite: site.name,
      })),
    }));
  }
}



