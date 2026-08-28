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

  /**
   * Note un agent sur un assignment (1-5).
   * Met à jour rankingScore = moyenne de toutes ses notes.
   */
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

    // Recalcul de la moyenne
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

  async getRanking(limit = 50, sortBy: 'score' | 'days' = 'score') {
    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        rankingScore: true,
        agentType: true,
        _count: {
          select: {
            assignments: {
              where: { status: 'COMPLETED' },
            },
          },
        },
      },
      take: limit * 2, // over-fetch before sorting
    });

    const enriched = agents.map((a) => ({
      id: a.id,
      firstName: a.firstName,
      lastName: a.lastName,
      rankingScore: a.rankingScore,
      agentType: a.agentType,
      daysWorked: a._count.assignments,
    }));

    if (sortBy === 'days') {
      enriched.sort((a, b) => b.daysWorked - a.daysWorked);
    } else {
      enriched.sort((a, b) => b.rankingScore - a.rankingScore);
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
