import { Strategy } from 'passport-jwt';
import { AuthService } from './auth.service';
declare const JwtStrategy_base: new (...args: any[]) => Strategy;
export declare class JwtStrategy extends JwtStrategy_base {
    private readonly authService;
    constructor(authService: AuthService);
    validate(payload: {
        sub: string;
        role: string;
    }): Promise<{
        agentProfile: {
            id: string;
            isAvailable: boolean;
            availableUntil: Date | null;
            lastAvailabilityChange: Date;
            paidMonths: import("@prisma/client/runtime/library").JsonValue | null;
            unavailableDates: import("@prisma/client/runtime/library").JsonValue | null;
            userId: string;
        } | null;
    } & {
        id: string;
        email: string | null;
        phone: string;
        passwordHash: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        contractType: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        agentType: import(".prisma/client").$Enums.AgentType | null;
        mobileMoneyOperator: string | null;
        rankingScore: number;
    }>;
}
export {};
