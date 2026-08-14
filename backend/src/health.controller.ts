import { Controller, Get } from '@nestjs/common';

@Controller()
export class HealthController {
  @Get()
  root() {
    return {
      name: 'AS ONE API',
      status: 'ok',
      version: '1.0.0',
      time: new Date().toISOString(),
    };
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }
}
