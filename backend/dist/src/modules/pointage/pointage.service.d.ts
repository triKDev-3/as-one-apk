import { PrismaService } from '../../prisma/prisma.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
import { NotificationsGateway } from '../notifications/notifications.gateway';
export declare class PointageService {
    private readonly prisma;
    private readonly notifications;
    constructor(prisma: PrismaService, notifications: NotificationsGateway);
    create(dto: CreatePointageDto, createdById: string): Promise<any>;
}
