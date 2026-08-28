import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSiteDto } from './dto/create-site.dto';

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

  async findAll(type?: string, userId?: string, role?: string, all?: boolean) {
    const isFiltered = role === 'CHEF' && !all;
    const siteFilter = isFiltered && userId ? { chefs: { some: { chefId: userId } } } : {};

    return this.prisma.site.findMany({
      where: {
        isActive: true,
        ...(type ? { type: type as any } : {}),
        ...siteFilter,
      },
      include: {
        chefs: {
          include: {
            chef: { select: { id: true, firstName: true, lastName: true } },
          },
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string) {
    const site = await this.prisma.site.findUnique({
      where: { id },
      include: {
        assignments: {
          include: {
            agent: { select: { id: true, firstName: true, lastName: true, phone: true } },
          },
        },
      },
    });
    if (!site) throw new NotFoundException('Site introuvable');
    return site;
  }

  async assignChef(siteId: string, chefId: string) {
    return this.prisma.siteChef.create({
      data: { siteId, chefId },
    });
  }
}
