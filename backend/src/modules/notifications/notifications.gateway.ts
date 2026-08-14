import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

/**
 * Gateway temps réel AS ONE
 * Les clients s'authentifient via query token ou join room user:{id}
 */
@WebSocketGateway({
  cors: { origin: true, credentials: true },
  namespace: '/realtime',
})
export class NotificationsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(NotificationsGateway.name);
  /** userId → set of socket ids */
  private readonly userSockets = new Map<string, Set<string>>();

  handleConnection(client: Socket) {
    const userId =
      (client.handshake.query.userId as string) ||
      (client.handshake.auth?.userId as string);

    if (userId) {
      this.joinUser(userId, client);
      this.logger.log(`Client connected: ${client.id} → user ${userId}`);
    } else {
      this.logger.debug(`Anonymous socket: ${client.id}`);
    }
  }

  handleDisconnect(client: Socket) {
    for (const [userId, sockets] of this.userSockets.entries()) {
      if (sockets.has(client.id)) {
        sockets.delete(client.id);
        if (sockets.size === 0) this.userSockets.delete(userId);
        this.logger.log(`Client disconnected: ${client.id} (user ${userId})`);
        break;
      }
    }
  }

  @SubscribeMessage('join')
  handleJoin(
    @MessageBody() data: { userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    if (data?.userId) {
      this.joinUser(data.userId, client);
      return { ok: true, room: `user:${data.userId}` };
    }
    return { ok: false };
  }

  private joinUser(userId: string, client: Socket) {
    const room = `user:${userId}`;
    client.join(room);
    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId)!.add(client.id);
  }

  /** Notifie un utilisateur précis */
  notifyUser(userId: string, event: string, payload: unknown) {
    this.server.to(`user:${userId}`).emit(event, payload);
  }

  /** Broadcast global (ex: alertes direction) */
  broadcast(event: string, payload: unknown) {
    this.server.emit(event, payload);
  }

  // ---------- Helpers métier ----------

  notifyAssignment(agentId: string, assignment: unknown) {
    this.notifyUser(agentId, 'assignment:new', assignment);
  }

  notifyAssignmentResponse(
    chefId: string,
    payload: { assignmentId: string; accepted: boolean; agentName?: string },
  ) {
    this.notifyUser(chefId, 'assignment:response', payload);
  }

  notifyPointage(agentId: string, payload: unknown) {
    this.notifyUser(agentId, 'pointage:done', payload);
  }
}
