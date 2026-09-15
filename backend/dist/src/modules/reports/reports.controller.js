"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportsController = void 0;
const common_1 = require("@nestjs/common");
const reports_service_1 = require("./reports.service");
const create_task_dto_1 = require("./dto/create-task.dto");
const close_report_dto_1 = require("./dto/close-report.dto");
const update_summary_dto_1 = require("./dto/update-summary.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let ReportsController = class ReportsController {
    constructor(service) {
        this.service = service;
    }
    addTask(siteId, dto, req) {
        return this.service.addTask(siteId, dto, req.user.id);
    }
    listTasks(siteId) {
        return this.service.listTasks(siteId);
    }
    listTasksHistory(date, siteId) {
        return this.service.listTasksHistory({ date, siteId });
    }
    closeReport(siteId, dto, req) {
        return this.service.closeAndGenerateReport(siteId, dto, req.user.id);
    }
    listBySite(siteId) {
        return this.service.listReportsBySite(siteId);
    }
    listAll() {
        return this.service.listAllReports();
    }
    getOne(id) {
        return this.service.getReport(id);
    }
    getLatest(siteId) {
        return this.service.getLatestReportBySite(siteId);
    }
    updateSummary(id, dto) {
        return this.service.updateReportSummary(id, dto.summary);
    }
};
exports.ReportsController = ReportsController;
__decorate([
    (0, common_1.Post)('sites/:siteId/tasks'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('siteId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, create_task_dto_1.CreateTaskDto, Object]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "addTask", null);
__decorate([
    (0, common_1.Get)('sites/:siteId/tasks'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "listTasks", null);
__decorate([
    (0, common_1.Get)('tasks'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('date')),
    __param(1, (0, common_1.Query)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "listTasksHistory", null);
__decorate([
    (0, common_1.Post)('sites/:siteId/close-report'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('siteId')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, close_report_dto_1.CloseReportDto, Object]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "closeReport", null);
__decorate([
    (0, common_1.Get)('sites/:siteId/reports'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "listBySite", null);
__decorate([
    (0, common_1.Get)('reports'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.COMPTABLE, client_1.Role.CHEF),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "listAll", null);
__decorate([
    (0, common_1.Get)('reports/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "getOne", null);
__decorate([
    (0, common_1.Get)('sites/:siteId/reports/latest'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "getLatest", null);
__decorate([
    (0, common_1.Patch)('reports/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_summary_dto_1.UpdateReportSummaryDto]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "updateSummary", null);
exports.ReportsController = ReportsController = __decorate([
    (0, common_1.Controller)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [reports_service_1.ReportsService])
], ReportsController);
//# sourceMappingURL=reports.controller.js.map