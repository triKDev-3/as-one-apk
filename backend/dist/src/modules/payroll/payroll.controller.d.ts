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
            createdAt: Date;
            agentId: string;
            periodId: string;
            baseAmount: import("@prisma/client/runtime/library").Decimal;
            primes: import("@prisma/client/runtime/library").Decimal;
            retenues: import("@prisma/client/runtime/library").Decimal;
            netAmount: import("@prisma/client/runtime/library").Decimal;
            details: import("@prisma/client/runtime/library").JsonValue | null;
        })[];
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        validatedAt: Date | null;
    }>;
    listPeriods(): Promise<({
        _count: {
            lines: number;
        };
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
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
            createdAt: Date;
            agentId: string;
            periodId: string;
            baseAmount: import("@prisma/client/runtime/library").Decimal;
            primes: import("@prisma/client/runtime/library").Decimal;
            retenues: import("@prisma/client/runtime/library").Decimal;
            netAmount: import("@prisma/client/runtime/library").Decimal;
            details: import("@prisma/client/runtime/library").JsonValue | null;
        })[];
    } & {
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
        validatedAt: Date | null;
    }>;
    adjustLine(id: string, dto: AdjustLineDto): Promise<{
        id: string;
        createdAt: Date;
        agentId: string;
        periodId: string;
        baseAmount: import("@prisma/client/runtime/library").Decimal;
        primes: import("@prisma/client/runtime/library").Decimal;
        retenues: import("@prisma/client/runtime/library").Decimal;
        netAmount: import("@prisma/client/runtime/library").Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    validate(id: string): Promise<{
        id: string;
        createdAt: Date;
        startDate: Date;
        endDate: Date;
        createdById: string;
        status: import(".prisma/client").$Enums.PayrollStatus;
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
        createdAt: Date;
        agentId: string;
        periodId: string;
        baseAmount: import("@prisma/client/runtime/library").Decimal;
        primes: import("@prisma/client/runtime/library").Decimal;
        retenues: import("@prisma/client/runtime/library").Decimal;
        netAmount: import("@prisma/client/runtime/library").Decimal;
        details: import("@prisma/client/runtime/library").JsonValue | null;
    })[]>;
}
