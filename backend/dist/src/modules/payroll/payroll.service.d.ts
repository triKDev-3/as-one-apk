import { PrismaService } from '../../prisma/prisma.service';
import { CreatePeriodDto } from './dto/create-period.dto';
import { AdjustLineDto } from './dto/adjust-line.dto';
import { Decimal } from '@prisma/client/runtime/library';
export declare class PayrollService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    createPeriod(dto: CreatePeriodDto, createdById: string): Promise<{
        lines: ({
            agent: {
                id: string;
                phone: string;
                firstName: string;
                lastName: string;
                agentType: import(".prisma/client").$Enums.AgentType | null;
            };
        } & {
            id: string;
            agentId: string;
            createdAt: Date;
            periodId: string;
            baseAmount: Decimal;
            primes: Decimal;
            retenues: Decimal;
            netAmount: Decimal;
            details: import("@prisma/client/runtime/library").JsonValue | null;
        })[];
    } & {
        id: string;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        validatedAt: Date | null;
    }>;
    computeLines(periodId: string): Promise<{
        id: string;
        agentId: string;
        createdAt: Date;
        periodId: string;
        baseAmount: Decimal;
        primes: Decimal;
        retenues: Decimal;
        netAmount: Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    }[]>;
    getPeriod(id: string): Promise<{
        lines: ({
            agent: {
                id: string;
                phone: string;
                firstName: string;
                lastName: string;
                agentType: import(".prisma/client").$Enums.AgentType | null;
            };
        } & {
            id: string;
            agentId: string;
            createdAt: Date;
            periodId: string;
            baseAmount: Decimal;
            primes: Decimal;
            retenues: Decimal;
            netAmount: Decimal;
            details: import("@prisma/client/runtime/library").JsonValue | null;
        })[];
    } & {
        id: string;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        validatedAt: Date | null;
    }>;
    listPeriods(): Promise<({
        _count: {
            lines: number;
        };
    } & {
        id: string;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        validatedAt: Date | null;
    })[]>;
    adjustLine(lineId: string, dto: AdjustLineDto): Promise<{
        id: string;
        agentId: string;
        createdAt: Date;
        periodId: string;
        baseAmount: Decimal;
        primes: Decimal;
        retenues: Decimal;
        netAmount: Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    validatePeriod(periodId: string): Promise<{
        id: string;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        validatedAt: Date | null;
    }>;
    getVirementListBySite(periodId: string, siteId: string): Promise<({
        agent: {
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
            mobileMoneyOperator: string | null;
        };
    } & {
        id: string;
        agentId: string;
        createdAt: Date;
        periodId: string;
        baseAmount: Decimal;
        primes: Decimal;
        retenues: Decimal;
        netAmount: Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    })[]>;
}
