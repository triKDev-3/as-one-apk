import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
export declare class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
    server: Server;
    private readonly logger;
    private readonly userSockets;
    handleConnection(client: Socket): void;
    handleDisconnect(client: Socket): void;
    handleJoin(data: {
        userId: string;
    }, client: Socket): {
        ok: boolean;
        room: string;
    } | {
        ok: boolean;
        room?: undefined;
    };
    private joinUser;
    notifyUser(userId: string, event: string, payload: unknown): void;
    broadcast(event: string, payload: unknown): void;
    notifyAssignment(agentId: string, assignment: unknown): void;
    notifyAssignmentResponse(chefId: string, payload: {
        assignmentId: string;
        accepted: boolean;
        agentName?: string;
    }): void;
    notifyPointage(agentId: string, payload: unknown): void;
}
