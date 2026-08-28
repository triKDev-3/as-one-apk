import { StatsService } from './stats.service';
export declare class StatsController {
    private readonly service;
    constructor(service: StatsService);
    getLiveStats(all: string, req: any): Promise<{
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
    getAgentsDetails(type: string, all: string, req: any): Promise<any[]>;
    getAgentsBySite(all: string, req: any): Promise<{
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
