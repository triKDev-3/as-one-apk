import { Injectable, ForbiddenException, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '@prisma/client';

@Injectable()
export class AgentService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Gros bouton disponibilité continue.
   * Règle métier : modifiable jusqu'à 22h.
   */
  async toggleAvailability(userId: string, isAvailable: boolean) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { agentProfile: true },
    });

    if (!user || user.role !== Role.AGENT) {
      throw new ForbiddenException('Seul un agent peut modifier sa disponibilité');
    }

    // Règle 22h
    const now = new Date();
    if (now.getHours() >= 22) {
      throw new BadRequestException('Les disponibilités ne sont plus modifiables après 22h');
    }

    if (!user.agentProfile) {
      // Création automatique du profil si manquant
      await this.prisma.agentProfile.create({
        data: { userId, isAvailable },
      });
    } else {
      await this.prisma.agentProfile.update({
        where: { userId },
        data: {
          isAvailable,
          lastAvailabilityChange: now,
        },
      });
    }

    // Log léger
    const profile = await this.prisma.agentProfile.findUnique({ where: { userId } });
    if (profile) {
      await this.prisma.availabilityLog.create({
        data: {
          agentId: profile.id,
          isAvailable,
        },
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

    // Classement (top + position de l'agent)
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

  /**
   * Agents disponibles pour un chef (pool complète).
   */
  /**
   * Pool agents pour composition d'équipe.
   * Inclut les indisponibles (le chef peut les assigner → confirmation obligatoire).
   * Tri : disponibles d'abord, puis ranking.
   */
  async getAvailableAgents() {
    const agents = await this.prisma.user.findMany({
      where: {
        role: Role.AGENT,
        isActive: true,
      },
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

    // Disponibles en premier
    return agents.sort((a, b) => {
      const avA = a.agentProfile?.isAvailable === true ? 0 : 1;
      const avB = b.agentProfile?.isAvailable === true ? 0 : 1;
      if (avA !== avB) return avA - avB;
      return (b.rankingScore ?? 0) - (a.rankingScore ?? 0);
    });
  }

  /**
   * Historique des pointages d'un agent
   */
  async getPointagesHistory(agentId: string) {
    const pointages = await this.prisma.pointage.findMany({
      where: { agentId },
      include: {
        site: { select: { name: true } },
      },
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
   * Mon planning (calendrier)
   * Retourne les jours pointés et les indisponibilités
   */
  async getPlanning(agentId: string, monthKey?: string) {
    // Filtrage par mois si fourni (format: 'yyyy-MM'), sinon les 3 derniers mois
    const now = new Date();
    let startDate: Date;
    let endDate: Date;
    
    if (monthKey && /^\d{4}-\d{2}$/.test(monthKey)) {
      const [year, month] = monthKey.split('-').map(Number);
      startDate = new Date(year, month - 1, 1);
      endDate = new Date(year, month, 0, 23, 59, 59); // last day of month
    } else {
      startDate = new Date(now.getFullYear(), now.getMonth() - 2, 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
    }

    // Récupérer tous les pointages ARRIVEE sur la période
    const pointages = await this.prisma.pointage.findMany({
      where: { 
        agentId, 
        notedAt: { gte: startDate, lte: endDate },
        type: 'ARRIVEE' 
      },
      include: { site: { select: { name: true } } },
      orderBy: { notedAt: 'asc' },
    });

    // Récupérer les missions de routine de l'agent
    const routines = await this.prisma.assignment.findMany({
      where: {
        agentId,
        status: { in: ['CONFIRMED', 'PENDING_CONFIRMATION', 'LOCKED'] },
        missionType: 'ROUTINE'
      },
      include: { site: { select: { name: true } } }
    });

    // Récupérer les logs d'indisponibilité futures
    const profile = await this.prisma.agentProfile.findUnique({ where: { userId: agentId } });
    // Les indisponibilités futures sont stockées en JSON sur le profil
    const unavailableDates: string[] = (profile as any)?.unavailableDates ?? [];

    // Construire le map date -> statut (format attendu par le frontend)
    const calendarMap: Record<string, { status: string; siteName?: string }> = {};

    for (const routine of routines) {
      const days = routine.routineDays as unknown as number[];
      if (!Array.isArray(days) || days.length === 0) continue;
      // Parcourir chaque jour de startDate à endDate
      let current = new Date(startDate);
      while (current <= endDate) {
        // En js, getDay() = 0 (Dimanche) .. 6 (Samedi). On veut 1 (Lundi) .. 7 (Dimanche)
        const dayOfWeek = current.getDay() === 0 ? 7 : current.getDay();
        if (days.includes(dayOfWeek)) {
          // Vérifier si current >= routine.startDate (et <= endDate si défini)
          const rStart = new Date(routine.startDate);
          rStart.setHours(0, 0, 0, 0);
          let rEnd = routine.endDate ? new Date(routine.endDate) : null;
          if (rEnd) rEnd.setHours(23, 59, 59, 999);

          if (current >= rStart && (!rEnd || current <= rEnd)) {
            const dateKey = current.toISOString().split('T')[0];
            calendarMap[dateKey] = { status: 'routine', siteName: routine.site.name };
          }
        }
        current.setDate(current.getDate() + 1);
      }
    }

    // Jours travaillés (écrase la routine si pointage effectué)
    for (const p of pointages) {
      const dateKey = p.notedAt.toISOString().split('T')[0];
      calendarMap[dateKey] = { status: 'worked', siteName: p.site.name };
    }

    // Jours indisponibles marqués (futurs)
    for (const d of unavailableDates) {
      if (!calendarMap[d]) {
        calendarMap[d] = { status: 'unavailable' };
      }
    }

    return calendarMap;
  }

  /**
   * Rémunération mensuelle
   */
  async getRemuneration(agentId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: agentId },
      include: { agentProfile: true },
    });
    if (!user) throw new NotFoundException('Agent non trouvé');

    // On récupère tous les pointages (arrivées = jours travaillés)
    const pointages = await this.prisma.pointage.findMany({
      where: { agentId, type: 'ARRIVEE' },
      orderBy: { notedAt: 'desc' },
      include: { site: true },
    });

    // Grouper par mois (yyyy-MM)
    const monthlyData: Record<string, { daysWorked: number; totalAmount: number; details: any[] }> = {};

    for (const p of pointages) {
      const monthKey = p.notedAt.toISOString().substring(0, 7);
      if (!monthlyData[monthKey]) {
        monthlyData[monthKey] = { daysWorked: 0, totalAmount: 0, details: [] };
      }

      const rate = p.site.dailyRate ? Number(p.site.dailyRate) : (user.agentType === 'PERMANENT' ? 5000 : 3000);
      
      // On compte une arrivée comme un jour de travail
      // Note: "L'agent peut faire 2 chantiers dans une journée" -> il aura 2 arrivées, donc payé 2 fois ?
      // Selon le client : "l'agent peut faire 2 chantiers dans une journée en cas d'urgence... la notation se fait aussi par rapport à un chantier et une seule fois par jour"
      
      monthlyData[monthKey].daysWorked += 1;
      monthlyData[monthKey].totalAmount += rate;
      monthlyData[monthKey].details.push({
        date: p.notedAt,
        siteName: p.site.name,
        amount: rate,
      });
    }

    const paidMonths = user.agentProfile?.paidMonths as Record<string, string> || {};

    const result = Object.entries(monthlyData).map(([monthKey, data]) => ({
      monthKey,
      daysWorked: data.daysWorked,
      totalAmount: data.totalAmount,
      isPaid: !!paidMonths[monthKey],
      paidAt: paidMonths[monthKey] || null,
      details: data.details,
    }));

    return result.sort((a, b) => b.monthKey.localeCompare(a.monthKey));
  }

  /**
   * Marquer un mois comme payé
   */
  async markMonthPaid(agentId: string, monthKey: string) {
    const profile = await this.prisma.agentProfile.findUnique({
      where: { userId: agentId },
    });
    if (!profile) throw new NotFoundException('Profil agent non trouvé');

    const paidMonths = (profile.paidMonths as Record<string, string> || {});
    paidMonths[monthKey] = new Date().toISOString();

    await this.prisma.agentProfile.update({
      where: { userId: agentId },
      data: { paidMonths },
    });

    return { success: true, monthKey, paidAt: paidMonths[monthKey] };
  }

  /**
   * Marquer un jour spécifique comme disponible ou non (pour les jours futurs)
   */
  async markDayAvailability(userId: string, date: string, available: boolean) {
    // Basic validation of date string (YYYY-MM-DD)
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
      // Remove from unavailableDates if it exists
      unavailableDates = unavailableDates.filter((d) => d !== date);
    } else {
      // Add to unavailableDates if it doesn't exist
      if (!unavailableDates.includes(date)) {
        unavailableDates.push(date);
      }
    }

    await this.prisma.agentProfile.update({
      where: { userId },
      data: {
        unavailableDates,
      },
    });

    return { success: true, date, available };
  }
}
