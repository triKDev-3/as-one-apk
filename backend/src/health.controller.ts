import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get()
  root() {
    return {
      name: 'AS ONE API',
      status: 'ok',
      version: process.env.APP_VERSION || '1.0.5',
      time: new Date().toISOString(),
    };
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }

  /**
   * Version mobile publique (pas d'auth).
   * Config Render / .env :
   *   APP_VERSION=1.0.5
   *   APP_BUILD=6
   *   APP_APK_URL=https://.../asone-release-arm64.apk
   *   APP_FORCE_UPDATE=false
   *   APP_NOTES=Corrections pointage + photos
   */
  @Get('app/version')
  appVersion() {
    const version = process.env.APP_VERSION || '1.0.5';
    const build = parseInt(process.env.APP_BUILD || '6', 10);
    const apkUrl = process.env.APP_APK_URL || '';
    const forceUpdate =
      (process.env.APP_FORCE_UPDATE || 'false').toLowerCase() === 'true';
    const notes =
      process.env.APP_NOTES ||
      'Une nouvelle version de AS ONE est disponible.';

    return {
      version,
      build,
      minBuild: parseInt(process.env.APP_MIN_BUILD || '1', 10),
      apkUrl,
      forceUpdate,
      notes,
      platform: 'android',
    };
  }
}
