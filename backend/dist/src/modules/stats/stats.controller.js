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
exports.StatsController = void 0;
const common_1 = require("@nestjs/common");
const stats_service_1 = require("./stats.service");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let StatsController = class StatsController {
    constructor(service) {
        this.service = service;
    }
    getLiveStats(all, req) {
        return this.service.getLiveStats(req.user.id, req.user.role, all === 'true');
    }
    getAgentsDetails(type, all, req) {
        return this.service.getAgentsDetails(type, req.user.id, req.user.role, all === 'true');
    }
    getAgentsBySite(all, req) {
        return this.service.getAgentsBySite(req.user.id, req.user.role, all === 'true');
    }
    getCalendar(month, all, siteId, req) {
        const monthKey = month && /^\d{4}-\d{2}$/.test(month)
            ? month
            : new Date().toISOString().slice(0, 7);
        return this.service.getChefCalendar(req.user.id, req.user.role, monthKey, all === 'true', siteId || undefined);
    }
    getInterventions(from, to, siteId, status, all, req) {
        return this.service.getInterventionsHistory({
            userId: req.user.id,
            role: req.user.role,
            all: all === 'true',
            from,
            to,
            siteId,
            status,
        });
    }
};
exports.StatsController = StatsController;
__decorate([
    (0, common_1.Get)('live'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('all')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], StatsController.prototype, "getLiveStats", null);
__decorate([
    (0, common_1.Get)('agents-details'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('type')),
    __param(1, (0, common_1.Query)('all')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], StatsController.prototype, "getAgentsDetails", null);
__decorate([
    (0, common_1.Get)('agents-by-site'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('all')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], StatsController.prototype, "getAgentsBySite", null);
__decorate([
    (0, common_1.Get)('calendar'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('month')),
    __param(1, (0, common_1.Query)('all')),
    __param(2, (0, common_1.Query)('siteId')),
    __param(3, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, Object]),
    __metadata("design:returntype", void 0)
], StatsController.prototype, "getCalendar", null);
__decorate([
    (0, common_1.Get)('interventions'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('from')),
    __param(1, (0, common_1.Query)('to')),
    __param(2, (0, common_1.Query)('siteId')),
    __param(3, (0, common_1.Query)('status')),
    __param(4, (0, common_1.Query)('all')),
    __param(5, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, Object]),
    __metadata("design:returntype", void 0)
], StatsController.prototype, "getInterventions", null);
exports.StatsController = StatsController = __decorate([
    (0, common_1.Controller)('stats'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [stats_service_1.StatsService])
], StatsController);
//# sourceMappingURL=stats.controller.js.map