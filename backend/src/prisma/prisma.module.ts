import { Global, Module } from '@nestjs/common';
import { BootstrapService } from './bootstrap.service';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService, BootstrapService],
  exports: [PrismaService],
})
export class PrismaModule {}
