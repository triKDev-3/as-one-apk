import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePeriodDto } from './dto/create-period.dto';
import { AdjustLineDto } from './dto/adjust-line.dto';
import { PayrollStatus, Role, AgentType } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class PayrollService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Crée une période de paie et lance le pré-calcul (simulation).
   * Intervalle de dates libre.
   */
  async createPeriod(dto: CreatePeriodDto, createdById: string) {
    const start = new Date(dto.startDate);
    const end = new Date(dto.endDate);

    if (end < start) {
      throw new BadRequestException('La date de fin doit être après la date de début');
    }

    const period = await this.prisma.payrollPeriod.create({
      data: {
        startDate: start,
        endDate: end,
        status: PayrollStatus.SIMULATION,
        createdById,
      },
    });

    // Pré-calcul automatique
    await this.computeLines(period.id);

    return this.getPeriod(period.id);
  }

  /**
   * Calcul des lignes de paie pour une période.
   * Règles :
   * - Temporaire classique : jours pointés × tarif journalier du site
   * - Remplacement permanence : prorata du salaire mensuel
   * - Retenues matériel appliquées automatiquement
   * - Primes / retenues manuelles ajoutables ensuite
   */
  async computeLines(periodId: string) {
    const period = await this.prisma.payrollPeriod.findUnique({
      where: { id: periodId },
    });
    if (!period) throw new NotFoundException('Période introuvable');

    // On récupère tous les agents actifs
    const agents = await this.prisma.user.findMany({
      where: { role: Role.AGENT, isActive: true },
      include: { agentProfile: true },
    });

    const lines = [];

    for (const agent of agents) {
      // Pointages dans la période
      const pointages = await this.prisma.pointage.findMany({
        where: {
          agentId: agent.id,
          notedAt: { gte: period.startDate, lte: period.endDate },
          type: { in: ['DEPART', 'PRESENCE_PERMANENCE'] },
        },
        include: {
          site: true,
          assignment: true,
        },
      });

      // Retenues matériel dans la période
      const retenues = await this.prisma.materialRetention.findMany({
        where: {
          isApplied: true,
          createdAt: { gte: period.startDate, lte: period.endDate },
          OR: [
            { agentId: agent.id },
            { target: 'WHOLE_GROUP' }, // sera réparti plus bas si besoin
          ],
        },
        include: { movement: { include: { item: true } } },
      });

      let baseAmount = 0;
      const details: any[] = [];

      // Calcul simple : 1 jour = 1 pointage arrivée / présence
      const daysWorked = new Set(
        pointages.map((p) => p.notedAt.toISOString().slice(0, 10)),
      ).size;

      // Tarif : on prend le tarif du premier site trouvé, sinon 0
      // (en production on raffinera par site / jour)
      let dailyRate = 0;
      if (pointages.length > 0 && pointages[0].site.dailyRate) {
        dailyRate = Number(pointages[0].site.dailyRate);
      }

      // Cas spécial : temporaire en remplacement permanence → prorata mensuel
      // (simplifié ici : on utilise le dailyRate si disponible)
      baseAmount = daysWorked * dailyRate;

      details.push({
        type: 'jours_travailles',
        days: daysWorked,
        dailyRate,
        amount: baseAmount,
      });

      const penalties = await this.prisma.incidentPenalty.findMany({
        where: {
          agentId: agent.id,
          createdAt: { gte: period.startDate, lte: period.endDate },
        },
      });

      // Retenues individuelles
      let totalRetenues = 0;
      for (const r of retenues) {
        if (r.agentId === agent.id) {
          totalRetenues += Number(r.amount);
          details.push({
            type: 'retenue_materiel',
            amount: Number(r.amount),
            item: r.movement?.item?.name,
          });
        }
      }
      for (const pen of penalties) {
        totalRetenues += Number(pen.amount);
        details.push({
          type: 'penalite_incident',
          amount: Number(pen.amount),
          reason: pen.reason,
        });
      }

      // Pour WHOLE_GROUP on pourrait diviser par le nombre d’agents pointés le jour J
      // (logique avancée à affiner plus tard)

      const net = baseAmount - totalRetenues;

      const line = await this.prisma.payrollLine.create({
        data: {
          periodId,
          agentId: agent.id,
          baseAmount,
          primes: 0,
          retenues: totalRetenues,
          netAmount: net,
          details,
        },
      });

      lines.push(line);
    }

    return lines;
  }

  async getPeriod(id: string) {
    const period = await this.prisma.payrollPeriod.findUnique({
      where: { id },
      include: {
        lines: {
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
          orderBy: { netAmount: 'desc' },
        },
      },
    });
    if (!period) throw new NotFoundException();
    return period;
  }

  async listPeriods() {
    return this.prisma.payrollPeriod.findMany({
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { lines: true } } },
    });
  }

  /**
   * Ajustement manuel (prime ou retenue exceptionnelle)
   */
  async adjustLine(lineId: string, dto: AdjustLineDto) {
    const line = await this.prisma.payrollLine.findUnique({ where: { id: lineId } });
    if (!line) throw new NotFoundException();

    const primes = dto.primes !== undefined ? dto.primes : Number(line.primes);
    const retenues = dto.retenues !== undefined ? dto.retenues : Number(line.retenues);
    const net = Number(line.baseAmount) + primes - retenues;

    return this.prisma.payrollLine.update({
      where: { id: lineId },
      data: {
        primes,
        retenues,
        netAmount: net,
      },
    });
  }

  /**
   * Validation définitive de la période
   */
  async validatePeriod(periodId: string) {
    return this.prisma.payrollPeriod.update({
      where: { id: periodId },
      data: {
        status: PayrollStatus.VALIDATED,
        validatedAt: new Date(),
      },
    });
  }

  /**
   * Liste de virements par chantier (pour les chefs)
   */
  async getVirementListBySite(periodId: string, siteId: string) {
    // On récupère les agents qui ont pointé sur ce site pendant la période
    const period = await this.prisma.payrollPeriod.findUnique({ where: { id: periodId } });
    if (!period) throw new NotFoundException();

    const pointages = await this.prisma.pointage.findMany({
      where: {
        siteId,
        notedAt: { gte: period.startDate, lte: period.endDate },
      },
      select: { agentId: true },
      distinct: ['agentId'],
    });

    const agentIds = pointages.map((p) => p.agentId);

    return this.prisma.payrollLine.findMany({
      where: {
        periodId,
        agentId: { in: agentIds },
      },
      include: {
        agent: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            phone: true,
            mobileMoneyOperator: true,
          },
        },
      },
    });
  }
}
