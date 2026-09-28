import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Envoi FCM (Firebase Cloud Messaging).
 * Actif seulement si FIREBASE_SERVICE_ACCOUNT_JSON est défini (JSON stringifié).
 * Sans cette variable : no-op (Socket.IO + notifs in-app restent actifs).
 */
@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private messaging: any = null;
  private enabled = false;

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!raw) {
      this.logger.warn(
        'FCM désactivé — définis FIREBASE_SERVICE_ACCOUNT_JSON pour activer le push système',
      );
      return;
    }
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      const cred =
        typeof raw === 'string' ? JSON.parse(raw) : raw;
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(cred),
        });
      }
      this.messaging = admin.messaging();
      this.enabled = true;
      this.logger.log('FCM initialisé');
    } catch (e) {
      this.logger.error(
        `FCM init échouée: ${e instanceof Error ? e.message : e}`,
      );
    }
  }

  async registerToken(userId: string, token: string, platform = 'android') {
    if (!token || token.length < 20) return { ok: false };
    await this.prisma.deviceToken.upsert({
      where: { userId_token: { userId, token } },
      create: { userId, token, platform },
      update: { platform, updatedAt: new Date() },
    });
    return { ok: true };
  }

  async removeToken(userId: string, token: string) {
    await this.prisma.deviceToken.deleteMany({
      where: { userId, token },
    });
    return { ok: true };
  }

  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ) {
    if (!this.enabled || !this.messaging) return;

    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { token: true },
    });
    if (tokens.length === 0) return;

    const dataStr: Record<string, string> = {};
    if (data) {
      for (const [k, v] of Object.entries(data)) {
        dataStr[k] = typeof v === 'string' ? v : JSON.stringify(v);
      }
    }

    const invalid: string[] = [];
    for (const { token } of tokens) {
      try {
        await this.messaging.send({
          token,
          notification: { title, body },
          data: dataStr,
          android: {
            priority: 'high',
            notification: {
              channelId: 'asone_alerts',
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: { sound: 'default', badge: 1 },
            },
          },
        });
      } catch (e: any) {
        const code = e?.code || e?.errorInfo?.code || '';
        if (
          String(code).includes('registration-token-not-registered') ||
          String(code).includes('invalid-registration-token')
        ) {
          invalid.push(token);
        } else {
          this.logger.warn(`FCM send fail: ${e?.message || e}`);
        }
      }
    }

    if (invalid.length) {
      await this.prisma.deviceToken.deleteMany({
        where: { token: { in: invalid } },
      });
    }
  }
}
