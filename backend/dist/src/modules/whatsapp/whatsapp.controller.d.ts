import { WhatsappService } from './whatsapp.service';
import { WhatsappPairDto } from './dto/pair.dto';
export declare class WhatsappController {
    private readonly whatsappService;
    constructor(whatsappService: WhatsappService);
    requestPairing(req: any, dto: WhatsappPairDto): Promise<{
        code: string;
    }>;
    getStatus(req: any): Promise<{
        connected: boolean;
    }>;
    disconnect(req: any): Promise<{
        success: boolean;
    }>;
}
