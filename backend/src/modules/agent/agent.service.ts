import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class AgentService {
  constructor(private readonly prisma: PrismaService) {}

  async toggleAvailability(userId: string, isAvailable: boolean) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { agentProfile: true },
    });

    if (!user || user.role !== Role.AGENT) {
      throw new ForbiddenException('Seul un agent peut modifier sa disponibilité');
    }

    const now = new Date();
    const hourTogo = Number(
      new Intl.DateTimeFormat('en-GB', {
        timeZone: 'Africa/Lome',
        hour: 'numeric',
        hour12: false,
      }).format(now),
    );
    if ((hourTogo === 24 ? 0 : hourTogo) >= 22) {
      throw new BadRequestException('Les disponibilités ne sont plus modifiables après 22h');
    }

    if (!user.agentProfile) {
      await this.prisma.agentProfile.create({ data: { userId, isAvailable } });
    } else {
      await this.prisma.agentProfile.update({
        where: { userId },
        data: { isAvailable, lastAvailabilityChange: now },
      });
    }

    const profile = await this.prisma.agentProfile.findUnique({ where: { userId } });
    if (profile) {
      await this.prisma.availabilityLog.create({
        data: { agentId: profile.id, isAvailable },
      });
    }

    return { isAvailable, updatedAt: now };
  }

  async getMyDashboard(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        agentProfile: true,
        assignments: {
          where: {
            status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
          },
          include: {
            site: { select: { id: true, name: true, type: true, address: true } },
          },
          orderBy: { startDate: 'desc' },
          take: 20,
        },
        payrollLines: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: { period: true },
        },
      },
    });

    if (!user) throw new NotFoundException();

    const ranking = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      select: { id: true, firstName: true, lastName: true, rankingScore: true },
      orderBy: { rankingScore: 'desc' },
      take: 50,
    });

    const myRank = ranking.findIndex((a) => a.id === userId) + 1;

    return {
      profile: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        agentType: user.agentType,
        isAvailable: user.agentProfile?.isAvailable ?? true,
        rankingScore: user.rankingScore,
        myRank: myRank || null,
      },
      assignments: user.assignments,
      recentPayroll: user.payrollLines,
      ranking: ranking.map((a, i) => ({
        rank: i + 1,
        name: `${a.firstName} ${a.lastName}`,
        score: a.rankingScore,
        isMe: a.id === userId,
      })),
    };
  }

  async getAvailableAgents() {
    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        agentType: true,
        rankingScore: true,
        agentProfile: { select: { isAvailable: true, lastAvailabilityChange: true } },
      },
      orderBy: [{ rankingScore: 'desc' }, { lastName: 'asc' }],
    });

    return agents.sort((a, b) => {
      const avA = a.agentProfile?.isAvailable === true ? 0 : 1;
      const avB = b.agentProfile?.isAvailable === true ? 0 : 1;
      if (avA !== avB) return avA - avB;
      return (b.rankingScore ?? 0) - (a.rankingScore ?? 0);
    });
  }

  async getPointagesHistory(agentId: string) {
    const pointages = await this.prisma.pointage.findMany({
      where: { agentId },
      include: { site: { select: { name: true } } },
      orderBy: { notedAt: 'desc' },
    });

    return pointages.map((p) => ({
      id: p.id,
      siteName: p.site.name,
      type: p.type,
      date: p.notedAt.toISOString(),
      location: p.latitude && p.longitude ? { lat: p.latitude, lng: p.longitude } : null,
    }));
  }

  /**
   * Calendrier agent :
   * - assigned : jours couverts par affectation CONFIRMED/LOCKED (sauf dimanche)
   * - worked : pointage DEPART / PRESENCE
   * - unavailable : jour marqué par l'agent
   * - routine : missions routine
   */
  async getPlanning(agentId: string, monthKey?: string) {
    const now = new Date();
    let startDate: Date;
    let endDate: Date;

    if (monthKey && /^\d{4}-\d{2}$/.test(monthKey)) {
      const [year, month] = monthKey.split('-').map(Number);
      startDate = new Date(Date.UTC(year, month - 1, 1));
      endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59));
    } else {
      startDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 2, 1));
      endDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59));
    }

    const pointages = await this.prisma.pointage.findMany({
      where: {
        agentId,
        notedAt: { gte: startDate, lte: endDate },
        type: { in: ['DEPART', 'PRESENCE_PERMANENCE', 'ARRIVEE'] },
      },
      include: { site: { select: { name: true } } },
      orderBy: { notedAt: 'asc' },
    });

    const assignments = await this.prisma.assignment.findMany({
      where: {
        agentId,
        status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
      },
      include: { site: { select: { name: true } } },
    });

    const profile = await this.prisma.agentProfile.findUnique({ where: { userId: agentId } });
    const unavailableDates: string[] = (profile?.unavailableDates as string[]) || [];

    const calendarMap: Record<string, { status: string; siteName?: string }> = {};

    // 1) Affectations confirmées / en attente → jours de mission (hors dimanche)
    for (const asg of assignments) {
      const aStart = new Date(asg.startDate);
      aStart.setUTCHours(0, 0, 0, 0);
      const aEnd = asg.endDate
        ? new Date(asg.endDate)
        : new Date(Math.max(aStart.getTime(), endDate.getTime()));
      aEnd.setUTCHours(23, 59, 59, 999);

      const cursor = new Date(Math.max(aStart.getTime(), startDate.getTime()));
      const limit = new Date(Math.min(aEnd.getTime(), endDate.getTime()));

      while (cursor <= limit) {
        const dow = cursor.getUTCDay(); // 0 = dimanche
        if (dow !== 0) {
          if (asg.missionType === 'ROUTINE') {
            const days = asg.routineDays as unknown as number[];
            const dayOfWeek = dow === 0 ? 7 : dow;
            if (Array.isArray(days) && days.includes(dayOfWeek)) {
              const dateKey = cursor.toISOString().slice(0, 10);
              calendarMap[dateKey] = {
                status: 'routine',
                siteName: asg.site.name,
              };
            }
          } else {
            const dateKey = cursor.toISOString().slice(0, 10);
            // Ne pas écraser une routine plus précise
            if (!calendarMap[dateKey] || calendarMap[dateKey].status !== 'routine') {
              calendarMap[dateKey] = {
                status: asg.status === 'PENDING_CONFIRMATION' ? 'assigned_pending' : 'assigned',
                siteName: asg.site.name,
              };
            }
          }
        }
        cursor.setUTCDate(cursor.getUTCDate() + 1);
      }
    }

    // 2) Indispos déclarées (n'écrase pas worked)
    for (const d of unavailableDates) {
      if (!calendarMap[d] || calendarMap[d].status === 'assigned' || calendarMap[d].status === 'assigned_pending') {
        // On marque indispo mais on garde le site si déjà assigné
        calendarMap[d] = {
          status: 'unavailable',
          siteName: calendarMap[d]?.siteName,
        };
      } else if (!calendarMap[d]) {
        calendarMap[d] = { status: 'unavailable' };
      }
    }

    // 3) Jours réellement pointés (priorité max)
    for (const p of pointages) {
      const dateKey = p.notedAt.toISOString().slice(0, 10);
      calendarMap[dateKey] = { status: 'worked', siteName: p.site.name };
    }

    return calendarMap;
  }

  async getRemuneration(agentId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: agentId },
      include: { agentProfile: true },
    });
    if (!user) throw new NotFoundException('Agent non trouvé');

    const pointages = await this.prisma.pointage.findMany({
      where: { agentId, type: { in: ['DEPART', 'PRESENCE_PERMANENCE', 'ARRIVEE'] } },
      orderBy: { notedAt: 'desc' },
      include: { site: true },
    });

    const monthlyData: Record<
      string,
      { daysWorked: number; totalAmount: number; details: any[] }
    > = {};

    for (const p of pointages) {
      const monthKey = p.notedAt.toISOString().substring(0, 7);
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = { daysWorked: 0, totalAmount: 0, details: [] };
      }
      const rate = p.site.dailyRate
        ? Number(p.site.dailyRate)
        : user.agentType === 'PERMANENT'
          ? 5000
          : 3000;
      monthlyData[monthKey].daysWorked += 1;
      monthlyData[monthKey].totalAmount += rate;
      monthlyData[monthKey].details.push({
        date: p.notedAt,
        siteName: p.site.name,
        amount: rate,
      });
    }

    const paidMonths = (user.agentProfile?.paidMonths as Record<string, string>) || {};

    return Object.entries(monthlyData)
      .map(([monthKey, data]) => ({
        monthKey,
        daysWorked: data.daysWorked,
        totalAmount: data.totalAmount,
        isPaid: !!paidMonths[monthKey],
        paidAt: paidMonths[monthKey] || null,
        details: data.details,
      }))
      .sort((a, b) => b.monthKey.localeCompare(a.monthKey));
  }

  async markMonthPaid(agentId: string, monthKey: string) {
    const profile = await this.prisma.agentProfile.findUnique({
      where: { userId: agentId },
    });
    if (!profile) throw new NotFoundException('Profil agent non trouvé');

    const paidMonths = (profile.paidMonths as Record<string, string>) || {};
    paidMonths[monthKey] = new Date().toISOString();

    await this.prisma.agentProfile.update({
      where: { userId: agentId },
      data: { paidMonths },
    });

    return { success: true, monthKey, paidAt: paidMonths[monthKey] };
  }

  async markDayAvailability(userId: string, date: string, available: boolean) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException('Format de date invalide (YYYY-MM-DD attendu)');
    }

    const profile = await this.prisma.agentProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Profil agent non trouvé');
    }

    let unavailableDates: string[] = (profile.unavailableDates as string[]) || [];

    if (available) {
      unavailableDates = unavailableDates.filter((d) => d !== date);
    } else if (!unavailableDates.includes(date)) {
      unavailableDates.push(date);
    }

    await this.prisma.agentProfile.update({
      where: { userId },
      data: { unavailableDates },
    });

    return { success: true, date, available };
  }
}
