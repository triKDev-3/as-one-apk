import { PrismaService } from '../../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateProfileDto, ChangePasswordDto } from './dto/update-profile.dto';
import { Role } from '@prisma/client';
export declare class UsersService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateUserDto): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        isActive: boolean;
        createdAt: Date;
        agentType: import(".prisma/client").$Enums.AgentType | null;
    }>;
    findAll(role?: Role): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        isActive: boolean;
        agentType: import(".prisma/client").$Enums.AgentType | null;
        rankingScore: number;
        agentProfile: {
            isAvailable: boolean;
        } | null;
    }[]>;
    findOne(id: string): Promise<{
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
    setActive(id: string, isActive: boolean): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        isActive: boolean;
    }>;
    updateRole(id: string, newRole: Role): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
    }>;
    updateProfile(userId: string, dto: UpdateProfileDto): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        mobileMoneyOperator: string | null;
    }>;
    changePassword(userId: string, dto: ChangePasswordDto): Promise<{
        ok: boolean;
    }>;
    adminResetPassword(userId: string): Promise<{
        ok: boolean;
        message: string;
    }>;
}
