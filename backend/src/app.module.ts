import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { SitesModule } from './modules/sites/sites.module';
import { AssignmentsModule } from './modules/assignments/assignments.module';
import { AgentModule } from './modules/agent/agent.module';
import { MaterialModule } from './modules/material/material.module';
import { PayrollModule } from './modules/payroll/payroll.module';
import { PointageModule } from './modules/pointage/pointage.module';
import { RatingModule } from './modules/rating/rating.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { UploadModule } from './modules/upload/upload.module';
import { IncidentsModule } from './modules/incidents/incidents.module';
import { ReportsModule } from './modules/reports/reports.module';
import { StatsModule } from './modules/stats/stats.module';
import { WhatsappModule } from './modules/whatsapp/whatsapp.module';

@Module({
  controllers: [HealthController],
  imports: [
    PrismaModule,
    AuthModule,
    UsersModule,
    SitesModule,
    AssignmentsModule,
    AgentModule,
    MaterialModule,
    PayrollModule,
    PointageModule,
    RatingModule,
    NotificationsModule,
    UploadModule,
    IncidentsModule,
    ReportsModule,
    StatsModule,
    WhatsappModule,
  ],
})
export class AppModule {}
