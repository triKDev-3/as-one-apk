import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSiteDto } from './dto/create-site.dto';
import { UpdateSiteDto } from './dto/update-site.dto';
import { AssignmentStatus } from '@prisma/client';

@Injectable()
export class SitesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateSiteDto, createdById: string) {
    return this.prisma.site.create({
      data: {
        name: dto.name,
        type: dto.type,
        address: dto.address,
        location: dto.location,
        startDate: dto.startDate ? new Date(dto.startDate) : null,
        endDate: dto.endDate ? new Date(dto.endDate) : null,
        dailyRate: dto.dailyRate,
        nightRate: dto.nightRate ?? 4500,
        sundayRate: dto.sundayRate ?? 5000,
        bonusAmount: dto.bonusAmount,
        monthlySalary: dto.monthlySalary,
        fixedAmount: dto.fixedAmount,
        createdById,
      },
    });
  }

  async update(id: string, dto: UpdateSiteDto) {
    await this.findOne(id);
    return this.prisma.site.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.type !== undefined ? { type: dto.type } : {}),
        ...(dto.address !== undefined ? { address: dto.address } : {}),
        ...(dto.location !== undefined ? { location: dto.location } : {}),
        ...(dto.startDate !== undefined
          ? { startDate: dto.startDate ? new Date(dto.startDate) : null }
          : {}),
        ...(dto.endDate !== undefined
          ? { endDate: dto.endDate ? new Date(dto.endDate) : null }
          : {}),
        ...(dto.dailyRate !== undefined ? { dailyRate: dto.dailyRate } : {}),
        ...(dto.nightRate !== undefined ? { nightRate: dto.nightRate } : {}),
        ...(dto.sundayRate !== undefined ? { sundayRate: dto.sundayRate } : {}),
        ...(dto.bonusAmount !== undefined ? { bonusAmount: dto.bonusAmount } : {}),
        ...(dto.monthlySalary !== undefined
          ? { monthlySalary: dto.monthlySalary }
          : {}),
        ...(dto.fixedAmount !== undefined ? { fixedAmount: dto.fixedAmount } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
      },
    });
  }

  /** Désactivation (soft delete) — conserve l’historique. */
  async softDelete(id: string) {
    await this.findOne(id);
    return this.prisma.site.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async findAll(type?: string, userId?: string, role?: string, all?: boolean) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter =
      isFiltered && userId ? { chefs: { some: { chefId: userId } } } : {};

    const sites = await this.prisma.site.findMany({
      where: {
        isActive: true,
        ...(type ? { type: type as any } : {}),
        ...siteFilter,
      },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                isActive: true,
              },
            },
          },
        },
        _count: {
          select: {
            assignments: {
              where: {
                status: {
                  in: [
                    AssignmentStatus.PENDING_CONFIRMATION,
                    AssignmentStatus.CONFIRMED,
                    AssignmentStatus.LOCKED,
                  ],
                },
              },
            },
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    const enriched = await Promise.all(
      sites.map(async (s) => {
        const activeAssignments = await this.prisma.assignment.findMany({
          where: {
            siteId: s.id,
            status: {
              in: [
                AssignmentStatus.PENDING_CONFIRMATION,
                AssignmentStatus.CONFIRMED,
                AssignmentStatus.LOCKED,
              ],
            },
          },
          select: {
            id: true,
            status: true,
            startDate: true,
            endDate: true,
            agent: {
              select: { id: true, firstName: true, lastName: true },
            },
          },
          take: 50,
        });

        return {
          ...s,
          activeAgentsCount: s._count.assignments,
          activeAssignments: activeAssignments.map((a) => ({
            id: a.id,
            status: a.status,
            startDate: a.startDate,
            endDate: a.endDate,
            agentName: `${a.agent.firstName} ${a.agent.lastName}`.trim(),
            agentId: a.agent.id,
          })),
        };
      }),
    );

    return enriched;
  }

  async findOne(id: string) {
    const site = await this.prisma.site.findUnique({
      where: { id },
      include: {
        chefs: {
          include: {
            chef: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
        assignments: {
          where: {
            status: {
              in: [
                AssignmentStatus.PENDING_CONFIRMATION,
                AssignmentStatus.CONFIRMED,
                AssignmentStatus.LOCKED,
              ],
            },
          },
          include: {
            agent: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
              },
            },
          },
        },
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');
    return site;
  }

  async assignChef(siteId: string, chefId: string) {
    const existing = await this.prisma.siteChef.findUnique({
      where: { siteId_chefId: { siteId, chefId } },
    });
    if (existing) {
      throw new ConflictException('Ce chef est déjà assigné à ce site');
    }
    return this.prisma.siteChef.create({
      data: { siteId, chefId },
      include: {
        chef: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }

  async removeChef(siteId: string, chefId: string) {
    try {
      await this.prisma.siteChef.delete({
        where: { siteId_chefId: { siteId, chefId } },
      });
      return { ok: true };
    } catch {
      throw new NotFoundException('Assignation chef introuvable');
    }
  }
}
