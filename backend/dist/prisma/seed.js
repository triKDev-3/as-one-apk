"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcrypt = require("bcrypt");
const catalog_1 = require("../src/modules/material/catalog");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('🌱 Seeding AS ONE...');
    const passwordHash = await bcrypt.hash('asone123', 12);
    const admin = await prisma.user.upsert({
        where: { phone: '+22890000001' },
        update: {},
        create: {
            phone: '+22890000001',
            passwordHash,
            firstName: 'Direction',
            lastName: 'AS ONE',
            role: client_1.Role.ADMIN,
            email: 'admin@as-one.services',
        },
    });
    await prisma.user.upsert({
        where: { phone: '+22890000002' },
        update: {},
        create: {
            phone: '+22890000002',
            passwordHash,
            firstName: 'Afi',
            lastName: 'Comptable',
            role: client_1.Role.COMPTABLE,
        },
    });
    await prisma.user.upsert({
        where: { phone: '+22890000003' },
        update: {},
        create: {
            phone: '+22890000003',
            passwordHash,
            firstName: 'Koffi',
            lastName: 'Magasin',
            role: client_1.Role.MAGASINIER,
        },
    });
    const chef1 = await prisma.user.upsert({
        where: { phone: '+22890000011' },
        update: {},
        create: {
            phone: '+22890000011',
            passwordHash,
            firstName: 'Mensah',
            lastName: 'Chef',
            role: client_1.Role.CHEF,
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
            role: client_1.Role.CHEF,
        },
    });
    const agentsData = [
        { phone: '+22890100001', firstName: 'Kodjo', lastName: 'Agbeko', type: client_1.AgentType.TEMPORAIRE },
        { phone: '+22890100002', firstName: 'Ama', lastName: 'Sossou', type: client_1.AgentType.PERMANENT },
        { phone: '+22890100003', firstName: 'Yawo', lastName: 'Tetteh', type: client_1.AgentType.TEMPORAIRE },
        { phone: '+22890100004', firstName: 'Efua', lastName: 'Mensah', type: client_1.AgentType.PERMANENT },
        { phone: '+22890100005', firstName: 'Kofi', lastName: 'Adom', type: client_1.AgentType.TEMPORAIRE },
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
                role: client_1.Role.AGENT,
                agentType: a.type,
                rankingScore: 3.5 + Math.random() * 1.5,
                agentProfile: { create: { isAvailable: true } },
            },
        });
    }
    const site1 = await prisma.site.upsert({
        where: { id: 'seed-site-ecobank' },
        update: {},
        create: {
            id: 'seed-site-ecobank',
            name: 'Siège Ecobank Lomé',
            type: client_1.SiteType.CHANTIER,
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
            type: client_1.SiteType.PERMANENCE,
            address: 'Boulevard du Mono',
            dailyRate: 4000,
            createdById: admin.id,
        },
    });
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
    for (const row of catalog_1.DEFAULT_MATERIAL_CATALOG) {
        const existing = await prisma.materialItem.findFirst({
            where: { OR: [{ refCode: row.refCode }, { name: row.name }] },
        });
        if (existing) {
            await prisma.materialItem.update({
                where: { id: existing.id },
                data: {
                    refCode: row.refCode,
                    name: row.name,
                    category: row.category,
                    returnRequired: row.returnRequired,
                    isActive: true,
                },
            });
        }
        else {
            await prisma.materialItem.create({
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
//# sourceMappingURL=seed.js.map