import { OnModuleInit } from '@nestjs/common';
export declare class WhatsappService implements OnModuleInit {
    private readonly logger;
    private socks;
    private statuses;
    onModuleInit(): Promise<void>;
    private initializeSocket;
    requestPairingCode(userId: string, phone: string): Promise<string>;
    sendMessage(userId: string, phone: string, text: string): Promise<boolean>;
    isConnected(userId: string): boolean;
    disconnect(userId: string): Promise<void>;
}
