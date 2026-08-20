"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const health_controller_1 = require("./health.controller");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./modules/auth/auth.module");
const users_module_1 = require("./modules/users/users.module");
const sites_module_1 = require("./modules/sites/sites.module");
const assignments_module_1 = require("./modules/assignments/assignments.module");
const agent_module_1 = require("./modules/agent/agent.module");
const material_module_1 = require("./modules/material/material.module");
const payroll_module_1 = require("./modules/payroll/payroll.module");
const pointage_module_1 = require("./modules/pointage/pointage.module");
const rating_module_1 = require("./modules/rating/rating.module");
const notifications_module_1 = require("./modules/notifications/notifications.module");
const upload_module_1 = require("./modules/upload/upload.module");
const incidents_module_1 = require("./modules/incidents/incidents.module");
const reports_module_1 = require("./modules/reports/reports.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        controllers: [health_controller_1.HealthController],
        imports: [
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            sites_module_1.SitesModule,
            assignments_module_1.AssignmentsModule,
            agent_module_1.AgentModule,
            material_module_1.MaterialModule,
            payroll_module_1.PayrollModule,
            pointage_module_1.PointageModule,
            rating_module_1.RatingModule,
            notifications_module_1.NotificationsModule,
            upload_module_1.UploadModule,
            incidents_module_1.IncidentsModule,
            reports_module_1.ReportsModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map