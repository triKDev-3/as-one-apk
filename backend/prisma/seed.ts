/**
 * Seed AS ONE — données de démonstration
 * Usage: npx ts-node prisma/seed.ts
 * (après migrate)
 */
import { PrismaClient, Role, AgentType, SiteType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding AS ONE...');

  const passwordHash = await bcrypt.hash('asone123', 12);

  // Admin
  const admin = await prisma.user.upsert({
    where: { phone: '+22890000001' },
    update: {},
    create: {
      phone: '+22890000001',
      passwordHash,
      firstName: 'Direction',
      lastName: 'AS ONE',
      role: Role.ADMIN,
      email: 'admin@as-one.services',
    },
  });

  // Comptable
  await prisma.user.upsert({
    where: { phone: '+22890000002' },
    update: {},
    create: {
      phone: '+22890000002',
      passwordHash,
      firstName: 'Afi',
      lastName: 'Comptable',
      role: Role.COMPTABLE,
    },
  });

  // Magasinier
  await prisma.user.upsert({
    where: { phone: '+22890000003' },
    update: {},
    create: {
      phone: '+22890000003',
      passwordHash,
      firstName: 'Koffi',
      lastName: 'Magasin',
      role: Role.MAGASINIER,
    },
  });

  // Chefs
  const chef1 = await prisma.user.upsert({
    where: { phone: '+22890000011' },
    update: {},
    create: {
      phone: '+22890000011',
      passwordHash,
      firstName: 'Mensah',
      lastName: 'Chef',
      role: Role.CHEF,
    },
  });

  const chef2 = await prisma.user.upsert({
    where: { phone: '+22890000012' },
    update: {},
    create: {
      phone: '+22890000012',
      passwordHash,
      firstName: 'Akouvi',
      lastName: 'Secteur',
      role: Role.CHEF,
    },
  });

  // Agents
  const agentsData = [
    { phone: '+22890100001', firstName: 'Kodjo', lastName: 'Agbeko', type: AgentType.TEMPORAIRE },
    { phone: '+22890100002', firstName: 'Ama', lastName: 'Sossou', type: AgentType.PERMANENT },
    { phone: '+22890100003', firstName: 'Yawo', lastName: 'Tetteh', type: AgentType.TEMPORAIRE },
    { phone: '+22890100004', firstName: 'Efua', lastName: 'Mensah', type: AgentType.PERMANENT },
    { phone: '+22890100005', firstName: 'Kofi', lastName: 'Adom', type: AgentType.TEMPORAIRE },
  ];

  for (const a of agentsData) {
    await prisma.user.upsert({
      where: { phone: a.phone },
      update: {},
      create: {
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

  // Sites
  const site1 = await prisma.site.upsert({
    where: { id: 'seed-site-ecobank' },
    update: {},
    create: {
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

  const site2 = await prisma.site.upsert({
    where: { id: 'seed-site-togocom' },
    update: {},
    create: {
      id: 'seed-site-togocom',
      name: 'Permanence TOGOCOM',
      type: SiteType.PERMANENCE,
      address: 'Boulevard du Mono',
      dailyRate: 4000,
      createdById: admin.id,
    },
  });

  // Assigner chefs aux sites
  await prisma.siteChef.upsert({
    where: { siteId_chefId: { siteId: site1.id, chefId: chef1.id } },
    update: {},
    create: { siteId: site1.id, chefId: chef1.id },
  });
  await prisma.siteChef.upsert({
    where: { siteId_chefId: { siteId: site2.id, chefId: chef2.id } },
    update: {},
    create: { siteId: site2.id, chefId: chef2.id },
  });

  // Matériel catalogue
  const items = [
    { name: 'Aspirateur industriel', category: 'consignable', unitPrice: 85000 },
    { name: 'Monobrosse', category: 'consignable', unitPrice: 120000 },
    { name: 'Balai microfibre', category: 'consommable', unitPrice: 2500 },
    { name: 'Produit sol 5L', category: 'consommable', unitPrice: 8000 },
  ];

  for (const item of items) {
    const existing = await prisma.materialItem.findFirst({
      where: { name: item.name },
    });
    if (!existing) {
      await prisma.materialItem.create({ data: item });
    }
  }

  console.log('✅ Seed terminé');
  console.log('');
  console.log('Comptes de test (mot de passe: asone123) :');
  console.log('  Admin      +22890000001');
  console.log('  Comptable  +22890000002');
  console.log('  Magasinier +22890000003');
  console.log('  Chef 1     +22890000011');
  console.log('  Chef 2     +22890000012');
  console.log('  Agents     +22890100001 … +22890100005');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
