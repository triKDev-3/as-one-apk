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
    getChefCalendar(userId: string, role: string, monthKey: string, all: boolean, siteId?: string): Promise<{
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
            events: Array<{
                kind: string;
                label: string;
                siteName?: string;
                siteId?: string;
            }>;
        }>;
    }>;
    getInterventionsHistory(params: {
        userId: string;
        role: string;
        all: boolean;
        from?: string;
        to?: string;
        siteId?: string;
        status?: string;
    }): Promise<{
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
