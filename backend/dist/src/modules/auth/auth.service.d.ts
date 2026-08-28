import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
export declare class AuthService {
    private readonly prisma;
    private readonly jwt;
    constructor(prisma: PrismaService, jwt: JwtService);
    login(dto: LoginDto): Promise<{
        accessToken: string;
        user: {
            id: string;
            firstName: string;
            lastName: string;
            phone: string;
            role: import(".prisma/client").$Enums.Role;
            agentType: import(".prisma/client").$Enums.AgentType | null;
            isAvailable: boolean | null;
            rankingScore: number;
        };
    }>;
    hashPassword(plain: string): Promise<string>;
    validateUser(userId: string): Promise<{
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
