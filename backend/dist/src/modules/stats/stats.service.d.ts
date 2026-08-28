import { PrismaService } from '../../prisma/prisma.service';
export declare class StatsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getLiveStats(userId: string, role: string, all: boolean): Promise<{
        totalAgents: number;
        availableAgents: number;
        busyAgents: number;
        totalChefs: number;
        activeSites: number;
        todayPointages: number;
        openIncidents: number;
        pendingAssignments: number;
        updatedAt: string;
    }>;
    private enrichWithStatus;
    getAgentsDetails(type: string, userId: string, role: string, all: boolean): Promise<any[]>;
    getAgentsBySite(userId: string, role: string, all: boolean): Promise<{
        id: string;
        name: string;
        type: import(".prisma/client").$Enums.SiteType;
        agentCount: number;
        agents: {
            status: string;
            currentSite: string;
            id: string;
            phone: string;
            firstName: string;
            lastName: string;
            agentType: import(".prisma/client").$Enums.AgentType | null;
        }[];
    }[]>;
}
