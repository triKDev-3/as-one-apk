"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var WhatsappService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WhatsappService = void 0;
const common_1 = require("@nestjs/common");
const baileys_1 = require("@whiskeysockets/baileys");
const path = require("path");
const fs = require("fs");
let WhatsappService = WhatsappService_1 = class WhatsappService {
    constructor() {
        this.logger = new common_1.Logger(WhatsappService_1.name);
        this.socks = new Map();
        this.statuses = new Map();
    }
    async onModuleInit() {
        const authRoot = path.join(process.cwd(), 'baileys_auth_info');
        if (fs.existsSync(authRoot)) {
            const dirs = fs.readdirSync(authRoot);
            for (const dir of dirs) {
                const stats = fs.statSync(path.join(authRoot, dir));
                if (stats.isDirectory()) {
                    this.logger.log(`Attempting to reconnect WhatsApp for user ${dir}...`);
                    await this.initializeSocket(dir);
                }
            }
        }
    }
    async initializeSocket(userId) {
        if (this.socks.has(userId)) {
            return this.socks.get(userId);
        }
        const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
        const { state, saveCreds } = await (0, baileys_1.useMultiFileAuthState)(authDir);
        const sock = (0, baileys_1.default)({
            auth: state,
            printQRInTerminal: false,
        });
        sock.ev.on('creds.update', saveCreds);
        sock.ev.on('connection.update', async (update) => {
            const { connection, lastDisconnect } = update;
            if (connection === 'close') {
                this.statuses.set(userId, false);
                const shouldReconnect = lastDisconnect?.error?.output?.statusCode !==
                    baileys_1.DisconnectReason.loggedOut;
                this.logger.warn(`WhatsApp connection closed for user ${userId} — reconnecting: ${shouldReconnect}`);
                if (shouldReconnect) {
                    this.socks.delete(userId);
                    this.initializeSocket(userId);
                }
                else {
                    this.socks.delete(userId);
                    this.logger.error(`WhatsApp logged out for user ${userId}. Needs re-pairing.`);
                    try {
                        fs.rmSync(authDir, { recursive: true, force: true });
                    }
                    catch (e) { }
                }
            }
            else if (connection === 'open') {
                this.statuses.set(userId, true);
                this.logger.log(`✅ WhatsApp connected successfully for user ${userId}`);
            }
        });
        this.socks.set(userId, sock);
        return sock;
    }
    async requestPairingCode(userId, phone) {
        let cleaned = phone.replace(/\D/g, '');
        if (cleaned.length === 8) {
            cleaned = '228' + cleaned;
        }
        else if (!cleaned.startsWith('228') && cleaned.length < 11) {
            cleaned = '228' + cleaned;
        }
        if (this.socks.has(userId)) {
            const existing = this.socks.get(userId);
            existing?.ev?.removeAllListeners();
            try {
                existing?.logout();
            }
            catch (e) { }
            this.socks.delete(userId);
            this.statuses.set(userId, false);
            const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
            try {
                fs.rmSync(authDir, { recursive: true, force: true });
            }
            catch (e) { }
        }
        const sock = await this.initializeSocket(userId);
        await new Promise(resolve => setTimeout(resolve, 1000));
        if (sock.authState.creds.registered) {
            throw new common_1.BadRequestException('This account is already registered. Logout first.');
        }
        try {
            const code = await sock.requestPairingCode(cleaned);
            this.logger.log(`Generated pairing code for user ${userId}: ${code}`);
            return code;
        }
        catch (err) {
            this.logger.error(`Failed to generate pairing code for ${userId}`, err);
            throw new common_1.BadRequestException('Impossible de générer le code de couplage. Vérifiez le numéro.');
        }
    }
    async sendMessage(userId, phone, text) {
        const sock = this.socks.get(userId);
        const isConnected = this.statuses.get(userId);
        if (!sock || !isConnected) {
            this.logger.warn(`WhatsApp non connecté pour user ${userId} — message non envoyé à ${phone}`);
            return false;
        }
        try {
            let cleaned = phone.replace(/\D/g, '');
            if (cleaned.length === 8) {
                cleaned = '228' + cleaned;
            }
            const jid = `${cleaned}@s.whatsapp.net`;
            await sock.sendMessage(jid, { text });
            this.logger.log(`✉️  WhatsApp envoyé par ${userId} → ${phone}`);
            return true;
        }
        catch (error) {
            this.logger.error(`Échec envoi WhatsApp par ${userId} à ${phone}:`, error);
            return false;
        }
    }
    isConnected(userId) {
        return this.statuses.get(userId) ?? false;
    }
    async disconnect(userId) {
        if (this.socks.has(userId)) {
            const sock = this.socks.get(userId);
            sock?.ev?.removeAllListeners();
            try {
                sock?.logout();
            }
            catch (e) { }
            this.socks.delete(userId);
        }
        this.statuses.set(userId, false);
        const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
        try {
            fs.rmSync(authDir, { recursive: true, force: true });
        }
        catch (e) { }
        this.logger.log(`WhatsApp disconnected for user ${userId}`);
    }
};
exports.WhatsappService = WhatsappService;
exports.WhatsappService = WhatsappService = WhatsappService_1 = __decorate([
    (0, common_1.Injectable)()
], WhatsappService);
//# sourceMappingURL=whatsapp.service.js.map