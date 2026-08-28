import { Injectable, Logger, OnModuleInit, BadRequestException } from '@nestjs/common';
import makeWASocket, {
  DisconnectReason,
  useMultiFileAuthState,
} from '@whiskeysockets/baileys';
import { Boom } from '@hapi/boom';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class WhatsappService implements OnModuleInit {
  private readonly logger = new Logger(WhatsappService.name);
  
  // Map of userId -> socket instance
  private socks = new Map<string, any>();
  // Map of userId -> connection status
  private statuses = new Map<string, boolean>();

  async onModuleInit() {
    // Attempt to reconnect any existing sessions on startup
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

  /**
   * Initializes a WhatsApp socket for a specific user.
   */
  private async initializeSocket(userId: string) {
    if (this.socks.has(userId)) {
      return this.socks.get(userId);
    }

    const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
    const { state, saveCreds } = await useMultiFileAuthState(authDir);

    const sock = makeWASocket({
      auth: state,
      printQRInTerminal: false,
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on(
      'connection.update',
      async (update: { connection?: string; lastDisconnect?: { error?: Error } }) => {
        const { connection, lastDisconnect } = update;

        if (connection === 'close') {
          this.statuses.set(userId, false);
          const shouldReconnect =
            (lastDisconnect?.error as Boom)?.output?.statusCode !==
            DisconnectReason.loggedOut;
          
          this.logger.warn(`WhatsApp connection closed for user ${userId} — reconnecting: ${shouldReconnect}`);
          
          if (shouldReconnect) {
            // Reconnect
            this.socks.delete(userId);
            this.initializeSocket(userId);
          } else {
            // Logged out
            this.socks.delete(userId);
            this.logger.error(`WhatsApp logged out for user ${userId}. Needs re-pairing.`);
            // Clean up auth dir
            try {
              fs.rmSync(authDir, { recursive: true, force: true });
            } catch (e) {}
          }
        } else if (connection === 'open') {
          this.statuses.set(userId, true);
          this.logger.log(`✅ WhatsApp connected successfully for user ${userId}`);
        }
      },
    );

    this.socks.set(userId, sock);
    return sock;
  }

  /**
   * Request a pairing code for a specific user.
   */
  async requestPairingCode(userId: string, phone: string): Promise<string> {
    // Clean phone and prepend 228 if needed
    let cleaned = phone.replace(/\D/g, '');
    if (cleaned.length === 8) {
      cleaned = '228' + cleaned;
    } else if (!cleaned.startsWith('228') && cleaned.length < 11) {
      // Basic fallback just in case
      cleaned = '228' + cleaned;
    }

    // Force disconnect and clean up if already exists to start fresh
    if (this.socks.has(userId)) {
      const existing = this.socks.get(userId);
      existing?.ev?.removeAllListeners();
      try {
        existing?.logout();
      } catch (e) {}
      this.socks.delete(userId);
      this.statuses.set(userId, false);
      const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
      try {
        fs.rmSync(authDir, { recursive: true, force: true });
      } catch (e) {}
    }

    const sock = await this.initializeSocket(userId);

    // Wait slightly to ensure socket is ready for pairing
    await new Promise(resolve => setTimeout(resolve, 1000));

    if (sock.authState.creds.registered) {
      throw new BadRequestException('This account is already registered. Logout first.');
    }

    try {
      const code: string = await sock.requestPairingCode(cleaned);
      this.logger.log(`Generated pairing code for user ${userId}: ${code}`);
      return code;
    } catch (err) {
      this.logger.error(`Failed to generate pairing code for ${userId}`, err);
      throw new BadRequestException('Impossible de générer le code de couplage. Vérifiez le numéro.');
    }
  }

  /**
   * Envoyer un message WhatsApp avec le compte d'un chef.
   */
  async sendMessage(userId: string, phone: string, text: string): Promise<boolean> {
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
    } catch (error) {
      this.logger.error(`Échec envoi WhatsApp par ${userId} à ${phone}:`, error);
      return false;
    }
  }

  isConnected(userId: string): boolean {
    return this.statuses.get(userId) ?? false;
  }

  async disconnect(userId: string): Promise<void> {
    if (this.socks.has(userId)) {
      const sock = this.socks.get(userId);
      sock?.ev?.removeAllListeners();
      try {
        sock?.logout();
      } catch (e) {}
      this.socks.delete(userId);
    }
    
    this.statuses.set(userId, false);
    
    // Clean up auth dir
    const authDir = path.join(process.cwd(), 'baileys_auth_info', userId);
    try {
      fs.rmSync(authDir, { recursive: true, force: true });
    } catch (e) {}
    
    this.logger.log(`WhatsApp disconnected for user ${userId}`);
  }
}
