import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { AgentType, Role, SiteType } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { DEFAULT_MATERIAL_CATALOG } from '../modules/material/catalog';
import { PrismaService } from './prisma.service';

/** Si la base est vide, crée les comptes de test (mot de passe asone123). */
@Injectable()
export class BootstrapService implements OnModuleInit {
  private readonly logger = new Logger(BootstrapService.name);

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    try {
      const count = await this.prisma.user.count();
      if (count > 0) {
        this.logger.log(`Base déjà peuplée (${count} utilisateurs) — seed ignoré`);
        return;
      }
      this.logger.log('Base vide — seed automatique…');
      await this.seed();
      this.logger.log('Seed OK — login admin +22890000001 / asone123');
    } catch (e) {
      this.logger.error('Seed automatique échoué', e instanceof Error ? e.stack : e);
    }
  }

  private async seed() {
    const passwordHash = await bcrypt.hash('asone123', 12);

    const admin = await this.prisma.user.create({
      data: {
        phone: '+22890000001',
        passwordHash,
        firstName: 'Direction',
        lastName: 'AS ONE',
        role: Role.ADMIN,
        email: 'admin@as-one.services',
      },
    });

    await this.prisma.user.create({
      data: {
        phone: '+22890000002',
        passwordHash,
        firstName: 'Afi',
        lastName: 'Comptable',
        role: Role.COMPTABLE,
      },
    });

    await this.prisma.user.create({
      data: {
        phone: '+22890000003',
        passwordHash,
        firstName: 'Koffi',
        lastName: 'Magasin',
        role: Role.MAGASINIER,
      },
    });

    const chef1 = await this.prisma.user.create({
      data: {
        phone: '+22890000011',
        passwordHash,
        firstName: 'Mensah',
        lastName: 'Chef',
        role: Role.CHEF,
      },
    });

    const chef2 = await this.prisma.user.create({
      data: {
        phone: '+22890000012',
        passwordHash,
        firstName: 'Akouvi',
        lastName: 'Secteur',
        role: Role.CHEF,
      },
    });

    const agents = [
      { phone: '+22890100001', firstName: 'Kodjo', lastName: 'Agbeko', type: AgentType.TEMPORAIRE },
      { phone: '+22890100002', firstName: 'Ama', lastName: 'Sossou', type: AgentType.PERMANENT },
      { phone: '+22890100003', firstName: 'Yawo', lastName: 'Tetteh', type: AgentType.TEMPORAIRE },
      { phone: '+22890100004', firstName: 'Efua', lastName: 'Mensah', type: AgentType.PERMANENT },
      { phone: '+22890100005', firstName: 'Kofi', lastName: 'Adom', type: AgentType.TEMPORAIRE },
    ];

    for (const a of agents) {
      await this.prisma.user.create({
        data: {
          phone: a.phone,
          passwordHash,
          firstName: a.firstName,
          lastName: a.lastName,
          role: Role.AGENT,
          agentType: a.type,
          rankingScore: 3.5 + Math.random() * 1.5,
          agentProfile: { create: { isAvailable: true } },
        },
      });
    }

    const site1 = await this.prisma.site.create({
      data: {
        id: 'seed-site-ecobank',
        name: 'Siège Ecobank Lomé',
        type: SiteType.CHANTIER,
        address: 'Avenue de la Libération, Lomé',
        dailyRate: 3500,
        nightRate: 4500,
        sundayRate: 5000,
        startDate: new Date(),
        endDate: new Date(Date.now() + 7 * 24 * 3600 * 1000),
        createdById: admin.id,
      },
    });

    const site2 = await this.prisma.site.create({
      data: {
        id: 'seed-site-togocom',
        name: 'Permanence TOGOCOM',
        type: SiteType.PERMANENCE,
        address: 'Boulevard du Mono',
        dailyRate: 4000,
        createdById: admin.id,
      },
    });

    await this.prisma.siteChef.create({ data: { siteId: site1.id, chefId: chef1.id } });
    await this.prisma.siteChef.create({ data: { siteId: site2.id, chefId: chef2.id } });

    for (const row of DEFAULT_MATERIAL_CATALOG) {
      await this.prisma.materialItem.create({
        data: {
          refCode: row.refCode,
          name: row.name,
          category: row.category,
          returnRequired: row.returnRequired,
          unitPrice: 0,
        },
      });
    }
  }
}
