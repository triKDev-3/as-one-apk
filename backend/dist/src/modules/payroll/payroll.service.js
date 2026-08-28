"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PayrollService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const client_1 = require("@prisma/client");
let PayrollService = class PayrollService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createPeriod(dto, createdById) {
        const start = new Date(dto.startDate);
        const end = new Date(dto.endDate);
        if (end < start) {
            throw new common_1.BadRequestException('La date de fin doit être après la date de début');
        }
        const period = await this.prisma.payrollPeriod.create({
            data: {
                startDate: start,
                endDate: end,
                status: client_1.PayrollStatus.SIMULATION,
                createdById,
            },
        });
        await this.computeLines(period.id);
        return this.getPeriod(period.id);
    }
    async computeLines(periodId) {
        const period = await this.prisma.payrollPeriod.findUnique({
            where: { id: periodId },
        });
        if (!period)
            throw new common_1.NotFoundException('Période introuvable');
        const agents = await this.prisma.user.findMany({
            where: { role: client_1.Role.AGENT, isActive: true },
            include: { agentProfile: true },
        });
        const lines = [];
        for (const agent of agents) {
            const pointages = await this.prisma.pointage.findMany({
                where: {
                    agentId: agent.id,
                    notedAt: { gte: period.startDate, lte: period.endDate },
                    type: { in: ['ARRIVEE', 'PRESENCE_PERMANENCE'] },
                },
                include: {
                    site: true,
                    assignment: true,
                },
            });
            const retenues = await this.prisma.materialRetention.findMany({
                where: {
                    isApplied: true,
                    createdAt: { gte: period.startDate, lte: period.endDate },
                    OR: [
                        { agentId: agent.id },
                        { target: 'WHOLE_GROUP' },
                    ],
                },
                include: { movement: { include: { item: true } } },
            });
            let baseAmount = 0;
            const details = [];
            const daysWorked = new Set(pointages.map((p) => p.notedAt.toISOString().slice(0, 10))).size;
            let dailyRate = 0;
            if (pointages.length > 0 && pointages[0].site.dailyRate) {
                dailyRate = Number(pointages[0].site.dailyRate);
            }
            baseAmount = daysWorked * dailyRate;
            details.push({
                type: 'jours_travailles',
                days: daysWorked,
                dailyRate,
                amount: baseAmount,
            });
            let totalRetenues = 0;
            for (const r of retenues) {
                if (r.agentId === agent.id || r.target === 'ONE_AGENT') {
                    totalRetenues += Number(r.amount);
                    details.push({
                        type: 'retenue_materiel',
                        amount: Number(r.amount),
                        item: r.movement?.item?.name,
                    });
                }
            }
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
    async getPeriod(id) {
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
        if (!period)
            throw new common_1.NotFoundException();
        return period;
    }
    async listPeriods() {
        return this.prisma.payrollPeriod.findMany({
            orderBy: { createdAt: 'desc' },
            include: { _count: { select: { lines: true } } },
        });
    }
    async adjustLine(lineId, dto) {
        const line = await this.prisma.payrollLine.findUnique({ where: { id: lineId } });
        if (!line)
            throw new common_1.NotFoundException();
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
    async validatePeriod(periodId) {
        return this.prisma.payrollPeriod.update({
            where: { id: periodId },
            data: {
                status: client_1.PayrollStatus.VALIDATED,
                validatedAt: new Date(),
            },
        });
    }
    async getVirementListBySite(periodId, siteId) {
        const period = await this.prisma.payrollPeriod.findUnique({ where: { id: periodId } });
        if (!period)
            throw new common_1.NotFoundException();
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
};
exports.PayrollService = PayrollService;
exports.PayrollService = PayrollService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PayrollService);
//# sourceMappingURL=payroll.service.js.map