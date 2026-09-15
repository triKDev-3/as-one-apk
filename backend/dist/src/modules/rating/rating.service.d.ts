import { PrismaService } from '../../prisma/prisma.service';
import { CreateRatingDto } from './dto/create-rating.dto';
export declare class RatingService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    create(dto: CreateRatingDto, ratedById: string): Promise<{
        agent: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        agentId: string;
        assignmentId: string;
        ratedById: string;
        score: number;
        comment: string | null;
    }>;
    recomputeRanking(agentId: string): Promise<number>;
    getRanking(limit?: number, sortBy?: 'score' | 'days', monthKey?: string): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        rankingScore: number;
        ratingsCount: number;
        lifetimeScore: number;
        agentType: import(".prisma/client").$Enums.AgentType | null;
        daysWorked: number;
        month: string;
    }[]>;
    getByAssignment(assignmentId: string): Promise<({
        agent: {
            id: string;
            firstName: string;
            lastName: string;
        };
    } & {
        id: string;
        createdAt: Date;
        agentId: string;
        assignmentId: string;
        ratedById: string;
        score: number;
        comment: string | null;
    })[]>;
}
