import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { SetActiveDto } from './dto/set-active.dto';
import { UpdateProfileDto, ChangePasswordDto } from './dto/update-profile.dto';
import { Role } from '@prisma/client';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
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
    setActive(id: string, dto: SetActiveDto): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        isActive: boolean;
    }>;
    updateRole(id: string, dto: {
        role: Role;
    }): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
    }>;
    updateProfile(req: any, dto: UpdateProfileDto): Promise<{
        id: string;
        phone: string;
        firstName: string;
        lastName: string;
        role: import(".prisma/client").$Enums.Role;
        mobileMoneyOperator: string | null;
    }>;
    changePassword(req: any, dto: ChangePasswordDto): Promise<{
        ok: boolean;
    }>;
}
