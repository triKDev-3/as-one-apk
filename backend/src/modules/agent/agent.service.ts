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
}
