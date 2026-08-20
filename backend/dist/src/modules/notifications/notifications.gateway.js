"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var NotificationsGateway_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const common_1 = require("@nestjs/common");
let NotificationsGateway = NotificationsGateway_1 = class NotificationsGateway {
    constructor() {
        this.logger = new common_1.Logger(NotificationsGateway_1.name);
        this.userSockets = new Map();
    }
    handleConnection(client) {
        const userId = client.handshake.query.userId ||
            client.handshake.auth?.userId;
        if (userId) {
            this.joinUser(userId, client);
            this.logger.log(`Client connected: ${client.id} → user ${userId}`);
        }
        else {
            this.logger.debug(`Anonymous socket: ${client.id}`);
        }
    }
    handleDisconnect(client) {
        for (const [userId, sockets] of this.userSockets.entries()) {
            if (sockets.has(client.id)) {
                sockets.delete(client.id);
                if (sockets.size === 0)
                    this.userSockets.delete(userId);
                this.logger.log(`Client disconnected: ${client.id} (user ${userId})`);
                break;
            }
        }
    }
    handleJoin(data, client) {
        if (data?.userId) {
            this.joinUser(data.userId, client);
            return { ok: true, room: `user:${data.userId}` };
        }
        return { ok: false };
    }
    joinUser(userId, client) {
        const room = `user:${userId}`;
        client.join(room);
        if (!this.userSockets.has(userId)) {
            this.userSockets.set(userId, new Set());
        }
        this.userSockets.get(userId).add(client.id);
    }
    notifyUser(userId, event, payload) {
        this.server.to(`user:${userId}`).emit(event, payload);
    }
    broadcast(event, payload) {
        this.server.emit(event, payload);
    }
    notifyAssignment(agentId, assignment) {
        this.notifyUser(agentId, 'assignment:new', assignment);
    }
    notifyAssignmentResponse(chefId, payload) {
        this.notifyUser(chefId, 'assignment:response', payload);
    }
    notifyPointage(agentId, payload) {
        this.notifyUser(agentId, 'pointage:done', payload);
    }
};
exports.NotificationsGateway = NotificationsGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], NotificationsGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('join'),
    __param(0, (0, websockets_1.MessageBody)()),
    __param(1, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, socket_io_1.Socket]),
    __metadata("design:returntype", void 0)
], NotificationsGateway.prototype, "handleJoin", null);
exports.NotificationsGateway = NotificationsGateway = NotificationsGateway_1 = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: { origin: true, credentials: true },
        namespace: '/realtime',
    })
], NotificationsGateway);
//# sourceMappingURL=notifications.gateway.js.map