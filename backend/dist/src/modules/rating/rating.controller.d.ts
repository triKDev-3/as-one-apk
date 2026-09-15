import { RatingService } from './rating.service';
import { CreateRatingDto } from './dto/create-rating.dto';
export declare class RatingController {
    private readonly service;
    constructor(service: RatingService);
    create(dto: CreateRatingDto, req: any): Promise<{
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
    ranking(limit?: string, sortBy?: string, month?: string): Promise<{
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
    byAssignment(assignmentId: string): Promise<({
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
