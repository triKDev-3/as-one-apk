import { Module } from '@nestjs/common';
import { PermanenceService } from './permanence.service';
import { PermanenceController } from './permanence.controller';

@Module({
  controllers: [PermanenceController],
  providers: [PermanenceService],
  exports: [PermanenceService],
})
export class PermanenceModule {}
