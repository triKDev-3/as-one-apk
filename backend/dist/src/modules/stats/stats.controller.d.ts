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
    getCalendar(month: string, all: string, siteId: string, req: any): Promise<{
        month: string;
        siteId: string | null;
        summary: Record<string, {
            pointages: number;
            absents: number;
            incidents: number;
            pending: number;
            tasks: number;
            hasActivity: boolean;
        }>;
        days: Record<string, {
            pointages: number;
            absents: number;
            incidents: number;
            pending: number;
            tasks: number;
            events: {
                kind: string;
                label: string;
                siteName?: string;
                siteId?: string;
            }[];
        }>;
    }>;
    getInterventions(from: string, to: string, siteId: string, status: string, all: string, req: any): Promise<{
        count: number;
        byStatus: Record<string, number>;
        items: {
            id: string;
            status: import(".prisma/client").$Enums.AssignmentStatus;
            missionType: string | null;
            startDate: Date;
            endDate: Date | null;
            confirmedAt: Date | null;
            refusedAt: Date | null;
            isLocked: boolean;
            siteId: string;
            siteName: string;
            siteType: import(".prisma/client").$Enums.SiteType;
            agentId: string;
            agentName: string;
            agentPhone: string;
            agentContract: string;
            chefName: string | null;
            createdAt: Date;
        }[];
    }>;
}
