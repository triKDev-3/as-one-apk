import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
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
}
