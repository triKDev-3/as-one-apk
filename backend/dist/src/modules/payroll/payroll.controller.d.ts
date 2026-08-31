import { PayrollService } from './payroll.service';
import { CreatePeriodDto } from './dto/create-period.dto';
import { AdjustLineDto } from './dto/adjust-line.dto';
export declare class PayrollController {
    private readonly service;
    constructor(service: PayrollService);
    createPeriod(dto: CreatePeriodDto, req: any): Promise<{
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
            baseAmount: import("@prisma/client/runtime/library").Decimal;
            primes: import("@prisma/client/runtime/library").Decimal;
            retenues: import("@prisma/client/runtime/library").Decimal;
            netAmount: import("@prisma/client/runtime/library").Decimal;
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
            baseAmount: import("@prisma/client/runtime/library").Decimal;
            primes: import("@prisma/client/runtime/library").Decimal;
            retenues: import("@prisma/client/runtime/library").Decimal;
            netAmount: import("@prisma/client/runtime/library").Decimal;
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
    adjustLine(id: string, dto: AdjustLineDto): Promise<{
        id: string;
        agentId: string;
        createdAt: Date;
        periodId: string;
        baseAmount: import("@prisma/client/runtime/library").Decimal;
        primes: import("@prisma/client/runtime/library").Decimal;
        retenues: import("@prisma/client/runtime/library").Decimal;
        netAmount: import("@prisma/client/runtime/library").Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    validate(id: string): Promise<{
        id: string;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        startDate: Date;
        endDate: Date;
        createdAt: Date;
        validatedAt: Date | null;
    }>;
    virementList(periodId: string, siteId: string): Promise<({
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
        baseAmount: import("@prisma/client/runtime/library").Decimal;
        primes: import("@prisma/client/runtime/library").Decimal;
        retenues: import("@prisma/client/runtime/library").Decimal;
        netAmount: import("@prisma/client/runtime/library").Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    })[]>;
}
