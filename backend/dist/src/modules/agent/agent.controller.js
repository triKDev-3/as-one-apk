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
exports.AgentController = void 0;
const common_1 = require("@nestjs/common");
const toggle_availability_dto_1 = require("./dto/toggle-availability.dto");
const agent_service_1 = require("./agent.service");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let AgentController = class AgentController {
    constructor(agentService) {
        this.agentService = agentService;
    }
    toggleAvailability(req, dto) {
        return this.agentService.toggleAvailability(req.user.id, dto.isAvailable);
    }
    getMyDashboard(req) {
        return this.agentService.getMyDashboard(req.user.id);
    }
    getPointagesHistory(req) {
        return this.agentService.getPointagesHistory(req.user.id);
    }
    getPlanning(req) {
        return this.agentService.getPlanning(req.user.id);
    }
    getRemuneration(req) {
        return this.agentService.getRemuneration(req.user.id);
    }
    markMonthPaid(req, dto) {
        return this.agentService.markMonthPaid(req.user.id, dto.monthKey);
    }
    getAvailable() {
        return this.agentService.getAvailableAgents();
    }
    markDayAvailability(req, dto) {
        return this.agentService.markDayAvailability(req.user.id, dto.date, dto.available);
    }
};
exports.AgentController = AgentController;
__decorate([
    (0, common_1.Patch)('availability'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, toggle_availability_dto_1.ToggleAvailabilityDto]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "toggleAvailability", null);
__decorate([
    (0, common_1.Get)('me'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "getMyDashboard", null);
__decorate([
    (0, common_1.Get)('pointages'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "getPointagesHistory", null);
__decorate([
    (0, common_1.Get)('calendar'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "getPlanning", null);
__decorate([
    (0, common_1.Get)('remuneration'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "getRemuneration", null);
__decorate([
    (0, common_1.Post)('remuneration/mark-paid'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "markMonthPaid", null);
__decorate([
    (0, common_1.Get)('available'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "getAvailable", null);
__decorate([
    (0, common_1.Post)('availability-mark'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], AgentController.prototype, "markDayAvailability", null);
exports.AgentController = AgentController = __decorate([
    (0, common_1.Controller)('agent'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [agent_service_1.AgentService])
], AgentController);
//# sourceMappingURL=agent.controller.js.map