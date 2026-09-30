import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role, AssignmentStatus } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

type DayCell = {
  status: string;
  siteName?: string;
  sites?: string[];
  conflict?: boolean;
};

function coversDate(start: Date, end: Date | null, dayKey: string): boolean {
  const s = start.toISOString().slice(0, 10);
  if (dayKey < s) return false;
  if (!end) return true;
  const e = end.toISOString().slice(0, 10);
  return dayKey <= e;
}

@Injectable()
export class AgentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notify: NotificationsService,
  ) {}

  private async ensureAgentProfile(userId: string) {
    let profile = await this.prisma.agentProfile.findUnique({
      where: { userId },
    });
    if (!profile) {
      profile = await this.prisma.agentProfile.create({
        data: { userId, isAvailable: true, unavailableDates: [] },
      });
    }
    return profile;
  }

  private async notifyChefsOfUnavailability(
    agentId: string,
    agentName: string,
    opts: { continuous?: boolean; date?: string; cancelled?: boolean },
  ) {
    const assignments = await this.prisma.assignment.findMany({
      where: {
        agentId,
        status: {
          in: [
            AssignmentStatus.PENDING_CONFIRMATION,
            AssignmentStatus.CONFIRMED,
            AssignmentStatus.LOCKED,
          ],
        },
      },
      include: {
        site: {
          include: {
            chefs: { select: { chefId: true } },
          },
        },
      },
    });

    const chefIds = new Set<string>();
    const siteNames: string[] = [];

    for (const a of assignments) {
      siteNames.push(a.site.name);
      for (const c of a.site.chefs) chefIds.add(c.chefId);
      if (a.createdById) chefIds.add(a.createdById);
    }

    if (chefIds.size === 0) return;

    const sitesLabel =
      siteNames.length > 0
        ? [...new Set(siteNames)].slice(0, 3).join(', ')
        : 'un site';

    const body = opts.cancelled
      ? `${agentName} s'est déclaré(e) indisponible le ${opts.date} et a annulé son affectation sur ${sitesLabel}.`
      : opts.continuous
        ? `${agentName} s'est déclaré(e) indisponible (bouton continu) alors qu'il/elle est affecté(e) sur ${sitesLabel}.`
        : `${agentName} a marqué le ${opts.date} comme indisponible (affecté(e) sur ${sitesLabel}).`;

    await this.notify.pushMany([...chefIds], {
      title: opts.cancelled ? 'Affectation annulée par agent' : 'Agent indisponible',
      body,
      type: 'availability:unavailable',
      data: {
        agentId,
        date: opts.date ?? null,
        continuous: !!opts.continuous,
        cancelled: !!opts.cancelled,
        sites: [...new Set(siteNames)],
      },
    });
  }

  async toggleAvailability(userId: string, isAvailable: boolean) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { agentProfile: true },
    });

    if (!user || user.role !== Role.AGENT) {
      throw new ForbiddenException('Seul un agent peut modifier sa disponibilité');
    }

    const now = new Date();
    await this.ensureAgentProfile(userId);

    await this.prisma.agentProfile.update({
      where: { userId },
      data: { isAvailable, lastAvailabilityChange: now },
    });

    const profile = await this.prisma.agentProfile.findUnique({
      where: { userId },
    });
    if (profile) {
      await this.prisma.availabilityLog.create({
        data: { agentId: profile.id, isAvailable },
      });
    }

    if (!isAvailable) {
      const name = `${user.firstName} ${user.lastName}`.trim();
      await this.notifyChefsOfUnavailability(userId, name, {
        continuous: true,
      });
    }

    return { isAvailable, updatedAt: now.toISOString() };
  }

  async getMyDashboard(userId: string) {
    await this.ensureAgentProfile(userId);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        agentProfile: true,
        assignments: {
          where: {
            status: { in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'] },
          },
          include: {
            site: {
              select: { id: true, name: true, type: true, address: true },
            },
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
        agentProfile: {
          select: { isAvailable: true, lastAvailabilityChange: true },
        },
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
      take: 120,
    });

    return pointages.map((p) => ({
      id: p.id,
      siteName: p.site.name,
      type: p.type,
      date: p.notedAt.toISOString(),
      location:
        p.latitude && p.longitude
          ? { lat: p.latitude, lng: p.longitude }
          : null,
    }));
  }

  async getPlanning(agentId: string, monthKey?: string) {
    const now = new Date();
    let startDate: Date;
    let endDate: Date;
    let resolvedMonth: string;

    if (monthKey && /^\d{4}-\d{2}$/.test(monthKey)) {
      const [year, month] = monthKey.split('-').map(Number);
      startDate = new Date(Date.UTC(year, month - 1, 1));
      endDate = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));
      resolvedMonth = monthKey;
    } else {
      const y = now.getUTCFullYear();
      const m = now.getUTCMonth();
      startDate = new Date(Date.UTC(y, m, 1));
      endDate = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59, 999));
      resolvedMonth = `${y}-${String(m + 1).padStart(2, '0')}`;
    }

    await this.ensureAgentProfile(agentId);

    const [pointages, assignments, profile] = await Promise.all([
      this.prisma.pointage.findMany({
        where: {
          agentId,
          notedAt: { gte: startDate, lte: endDate },
          type: {
            in: ['DEPART', 'PRESENCE_PERMANENCE', 'ARRIVEE', 'ABSENT'],
          },
        },
        select: {
          type: true,
          notedAt: true,
          site: { select: { name: true } },
        },
        orderBy: { notedAt: 'asc' },
      }),
      this.prisma.assignment.findMany({
        where: {
          agentId,
          status: {
            in: ['CONFIRMED', 'LOCKED', 'PENDING_CONFIRMATION'],
          },
          startDate: { lte: endDate },
          OR: [{ endDate: null }, { endDate: { gte: startDate } }],
        },
        select: {
          status: true,
          startDate: true,
          endDate: true,
          missionType: true,
          routineDays: true,
          site: { select: { name: true } },
        },
      }),
      this.prisma.agentProfile.findUnique({
        where: { userId: agentId },
        select: { unavailableDates: true },
      }),
    ]);

    const unavailableDates: string[] = Array.isArray(profile?.unavailableDates)
      ? (profile!.unavailableDates as string[])
      : [];

    const calendarMap: Record<string, DayCell> = {};

    const setDay = (
      key: string,
      status: string,
      siteName?: string,
      opts?: { conflict?: boolean },
    ) => {
      const existing = calendarMap[key];
      if (!existing) {
        calendarMap[key] = {
          status,
          siteName,
          sites: siteName ? [siteName] : [],
          conflict: opts?.conflict,
        };
        return;
      }
      if (siteName) {
        const sites = new Set(existing.sites || []);
        sites.add(siteName);
        existing.sites = [...sites];
        if (!existing.siteName) existing.siteName = siteName;
        else if (existing.siteName !== siteName && sites.size > 1) {
          existing.siteName = existing.sites!.join(' \u00b7 ');
        }
      }
      if (opts?.conflict) existing.conflict = true;
      if (status === 'worked' || status === 'absent') {
        existing.status = status;
      }
    };

    for (const asg of assignments) {
      const aStart = new Date(asg.startDate);
      aStart.setUTCHours(0, 0, 0, 0);

      let aEnd: Date;
      if (asg.endDate) {
        aEnd = new Date(asg.endDate);
      } else if (
        asg.missionType === 'PERMANENTE' ||
        asg.missionType === 'ROUTINE'
      ) {
        aEnd = new Date(endDate);
      } else {
        aEnd = new Date(aStart);
      }
      aEnd.setUTCHours(23, 59, 59, 999);

      const cursor = new Date(Math.max(aStart.getTime(), startDate.getTime()));
      const limit = new Date(Math.min(aEnd.getTime(), endDate.getTime()));

      while (cursor <= limit) {
        const dow = cursor.getUTCDay();
        if (dow !== 0) {
          const dateKey = cursor.toISOString().slice(0, 10);

          if (asg.missionType === 'ROUTINE') {
            const days = asg.routineDays as unknown as number[];
            const dayOfWeek = dow === 0 ? 7 : dow;
            if (Array.isArray(days) && days.includes(dayOfWeek)) {
              setDay(dateKey, 'routine', asg.site.name);
            }
          } else {
            const status =
              asg.status === 'PENDING_CONFIRMATION'
                ? 'assigned_pending'
                : 'assigned';
            const cur = calendarMap[dateKey];
            if (
              !cur ||
              cur.status === 'routine' ||
              cur.status === 'assigned_pending'
            ) {
              setDay(dateKey, status, asg.site.name);
            } else if (cur.status === 'assigned') {
              setDay(dateKey, 'assigned', asg.site.name);
            }
          }
        }
        cursor.setUTCDate(cursor.getUTCDate() + 1);
      }
    }

    for (const d of unavailableDates) {
      if (
        d < startDate.toISOString().slice(0, 10) ||
        d > endDate.toISOString().slice(0, 10)
      ) {
        continue;
      }
      const cur = calendarMap[d];
      if (!cur) {
        calendarMap[d] = { status: 'unavailable' };
      } else if (cur.status === 'worked' || cur.status === 'absent') {
        // pointage gagne
      } else {
        calendarMap[d] = {
          status: 'unavailable',
          siteName: cur.siteName,
          sites: cur.sites,
          conflict:
            cur.status === 'assigned' ||
            cur.status === 'assigned_pending' ||
            cur.status === 'routine',
        };
      }
    }

    for (const p of pointages) {
      const dateKey = p.notedAt.toISOString().slice(0, 10);
      if (p.type === 'ABSENT') {
        const cur = calendarMap[dateKey];
        if (!cur || cur.status !== 'worked') {
          setDay(dateKey, 'absent', p.site.name);
        }
      } else {
        setDay(dateKey, 'worked', p.site.name);
      }
    }

    let worked = 0;
    let absent = 0;
    let assigned = 0;
    let pending = 0;
    let unavailable = 0;
    let conflicts = 0;

    for (const cell of Object.values(calendarMap)) {
      if (cell.conflict) conflicts++;
      switch (cell.status) {
        case 'worked':
          worked++;
          break;
        case 'absent':
          absent++;
          break;
        case 'assigned':
        case 'routine':
          assigned++;
          break;
        case 'assigned_pending':
          pending++;
          break;
        case 'unavailable':
          unavailable++;
          break;
      }
    }

    return {
      month: resolvedMonth,
      days: calendarMap,
      unavailableDates,
      stats: {
        worked,
        absent,
        assigned,
        pending,
        unavailable,
        conflicts,
      },
      canEditAvailability: true,
    };
  }

  async getRemuneration(agentId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: agentId },
      include: { agentProfile: true },
    });
    if (!user) throw new NotFoundException('Agent non trouvé');

    const pointages = await this.prisma.pointage.findMany({
      where: {
        agentId,
        type: { in: ['DEPART', 'PRESENCE_PERMANENCE', 'ARRIVEE'] },
      },
      orderBy: { notedAt: 'desc' },
      include: { site: true },
    });

    const monthlyData: Record<
      string,
      { daysWorked: number; totalAmount: number; details: any[] }
    > = {};

    for (const p of pointages) {
      const mk = p.notedAt.toISOString().substring(0, 7);
      if (!monthlyData[mk]) {
        monthlyData[mk] = { daysWorked: 0, totalAmount: 0, details: [] };
      }
      const rate = p.site.dailyRate
        ? Number(p.site.dailyRate)
        : user.agentType === 'PERMANENT'
          ? 5000
          : 3000;
      monthlyData[mk].daysWorked += 1;
      monthlyData[mk].totalAmount += rate;
      monthlyData[mk].details.push({
        date: p.notedAt,
        siteName: p.site.name,
        amount: rate,
      });
    }

    const paidMonths =
      (user.agentProfile?.paidMonths as Record<string, string>) || {};

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
    const profile = await this.ensureAgentProfile(agentId);
    const paidMonths = (profile.paidMonths as Record<string, string>) || {};
    paidMonths[monthKey] = new Date().toISOString();

    await this.prisma.agentProfile.update({
      where: { userId: agentId },
      data: { paidMonths },
    });

    return { success: true, monthKey, paidAt: paidMonths[monthKey] };
  }

  async markDayAvailability(
    userId: string,
    date: string,
    available: boolean,
    cancelAssignments = false,
  ) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException(
        'Format de date invalide (YYYY-MM-DD attendu)',
      );
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.role !== Role.AGENT) {
      throw new ForbiddenException('Seul un agent peut modifier sa disponibilité');
    }

    const todayKey = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'Africa/Lome',
    }).format(new Date());
    if (date < todayKey) {
      throw new BadRequestException(
        'Impossible de modifier un jour déjà passé',
      );
    }

    await this.ensureAgentProfile(userId);
    const profile = await this.prisma.agentProfile.findUnique({
      where: { userId },
    });
    if (!profile) throw new NotFoundException('Profil agent non trouvé');

    let cancelledCount = 0;
    let cancelledSites: string[] = [];

    // Indisponible alors qu'une affectation couvre ce jour
    if (!available) {
      const active = await this.prisma.assignment.findMany({
        where: {
          agentId: userId,
          status: {
            in: [
              AssignmentStatus.PENDING_CONFIRMATION,
              AssignmentStatus.CONFIRMED,
              AssignmentStatus.LOCKED,
            ],
          },
        },
        include: { site: { select: { id: true, name: true } } },
      });

      const covering = active.filter((a) =>
        coversDate(a.startDate, a.endDate, date),
      );

      if (covering.length > 0 && !cancelAssignments) {
        throw new ConflictException({
          message:
            'Vous avez une affectation ce jour. Confirmez pour annuler l\'affectation et vous marquer indisponible.',
          code: 'NEED_CANCEL_ASSIGNMENT',
          assignments: covering.map((a) => ({
            id: a.id,
            siteId: a.site.id,
            siteName: a.site.name,
            status: a.status,
          })),
        });
      }

      if (covering.length > 0 && cancelAssignments) {
        const ids = covering.map((a) => a.id);
        await this.prisma.assignment.updateMany({
          where: { id: { in: ids } },
          data: {
            status: AssignmentStatus.CANCELLED,
            isLocked: false,
          },
        });
        cancelledCount = ids.length;
        cancelledSites = [...new Set(covering.map((a) => a.site.name))];
      }
    }

    let unavailableDates: string[] = Array.isArray(profile.unavailableDates)
      ? [...(profile.unavailableDates as string[])]
      : [];

    if (available) {
      unavailableDates = unavailableDates.filter((d) => d !== date);
    } else if (!unavailableDates.includes(date)) {
      unavailableDates.push(date);
      unavailableDates.sort();
    }

    await this.prisma.agentProfile.update({
      where: { userId },
      data: {
        unavailableDates,
        lastAvailabilityChange: new Date(),
      },
    });

    if (!available) {
      const name = `${user.firstName} ${user.lastName}`.trim();
      await this.notifyChefsOfUnavailability(userId, name, {
        date,
        cancelled: cancelledCount > 0,
      });
    }

    return {
      success: true,
      date,
      available,
      unavailableDates,
      cancelledAssignments: cancelledCount,
      cancelledSites,
    };
  }
}
