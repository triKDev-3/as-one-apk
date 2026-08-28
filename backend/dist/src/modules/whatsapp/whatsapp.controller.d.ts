import { WhatsappService } from './whatsapp.service';
export declare class WhatsappController {
    private readonly whatsappService;
    constructor(whatsappService: WhatsappService);
    requestPairing(req: any, dto: {
        phone: string;
    }): Promise<{
        code: string;
    }>;
    getStatus(req: any): Promise<{
        connected: boolean;
    }>;
    disconnect(req: any): Promise<{
        success: boolean;
    }>;
}
