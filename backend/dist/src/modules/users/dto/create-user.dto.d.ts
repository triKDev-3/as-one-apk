import { AgentType, Role } from '@prisma/client';
export declare class CreateUserDto {
    phone: string;
    email?: string;
    password?: string;
    firstName: string;
    lastName: string;
    role: Role;
    agentType?: AgentType;
    mobileMoneyOperator?: string;
}
