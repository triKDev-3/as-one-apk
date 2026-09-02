import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateRatingDto } from './dto/create-rating.dto';
import { Role } from '@prisma/client';

@Injectable()
export class RatingService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateRatingDto, ratedById: string) {
    const assignment = await this.prisma.assignment.findUnique({
      where: { id: dto.assignmentId },
    });
    if (!assignment) throw new NotFoundException('Affectation introuvable');
    if (assignment.agentId !== dto.agentId) {
      throw new BadRequestException('Cet agent n\'est pas lié à cette affectation');
    }

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const existing = await this.prisma.rating.findFirst({
      where: {
        assignmentId: dto.assignmentId,
        agentId: dto.agentId,
        createdAt: { gte: startOfDay, lte: endOfDay },
      },
    });
    if (existing) {
      throw new ConflictException('Cet agent a déjà été noté aujourd\'hui pour ce chantier');
    }

    const rating = await this.prisma.rating.create({
      data: {
        assignmentId: dto.assignmentId,
        agentId: dto.agentId,
        ratedById,
        score: dto.score,
        comment: dto.comment,
      },
      include: {
        agent: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    await this.recomputeRanking(dto.agentId);
    return rating;
  }

  async recomputeRanking(agentId: string) {
    const agg = await this.prisma.rating.aggregate({
      where: { agentId },
      _avg: { score: true },
      _count: { score: true },
    });

    const avg = agg._avg.score ?? 0;
    await this.prisma.user.update({
      where: { id: agentId },
      data: { rankingScore: Math.round(avg * 100) / 100 },
    });

    return avg;
  }

  /**
   * Classement : score = moyenne notes ; jours = jours distincts avec DEPART ou PRESENCE_PERMANENCE.
   */
  async getRanking(limit = 50, sortBy: 'score' | 'days' = 'score') {
    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        rankingScore: true,
        agentType: true,
      },
    });

    const pointages = await this.prisma.pointage.findMany({
      where: {
        agentId: { in: agents.map((a) => a.id) },
        type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] },
      },
      select: { agentId: true, notedAt: true },
    });

    const daysByAgent = new Map<string, Set<string>>();
    for (const p of pointages) {
      const key = p.notedAt.toISOString().slice(0, 10);
      if (!daysByAgent.has(p.agentId)) daysByAgent.set(p.agentId, new Set());
      daysByAgent.get(p.agentId)!.add(key);
    }

    const enriched = agents.map((a) => ({
      id: a.id,
      firstName: a.firstName,
      lastName: a.lastName,
      rankingScore: a.rankingScore,
      agentType: a.agentType,
      daysWorked: daysByAgent.get(a.id)?.size ?? 0,
    }));

    if (sortBy === 'days') {
      enriched.sort((a, b) => b.daysWorked - a.daysWorked || b.rankingScore - a.rankingScore);
    } else {
      enriched.sort((a, b) => b.rankingScore - a.rankingScore || b.daysWorked - a.daysWorked);
    }

    return enriched.slice(0, limit);
  }

  async getByAssignment(assignmentId: string) {
    return this.prisma.rating.findMany({
      where: { assignmentId },
      include: {
        agent: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }
}
