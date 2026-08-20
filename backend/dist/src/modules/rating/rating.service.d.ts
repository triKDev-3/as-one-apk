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
        score: number;
        comment: string | null;
        ratedById: string;
    }>;
    recomputeRanking(agentId: string): Promise<number>;
    getRanking(limit?: number): Promise<{
        id: string;
        firstName: string;
        lastName: string;
        agentType: import(".prisma/client").$Enums.AgentType | null;
        rankingScore: number;
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
        score: number;
        comment: string | null;
        ratedById: string;
    })[]>;
}
