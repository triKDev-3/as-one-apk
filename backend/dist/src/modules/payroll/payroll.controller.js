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
exports.PayrollController = void 0;
const common_1 = require("@nestjs/common");
const payroll_service_1 = require("./payroll.service");
const create_period_dto_1 = require("./dto/create-period.dto");
const adjust_line_dto_1 = require("./dto/adjust-line.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let PayrollController = class PayrollController {
    constructor(service) {
        this.service = service;
    }
    createPeriod(dto, req) {
        return this.service.createPeriod(dto, req.user.id);
    }
    listPeriods() {
        return this.service.listPeriods();
    }
    getPeriod(id) {
        return this.service.getPeriod(id);
    }
    adjustLine(id, dto) {
        return this.service.adjustLine(id, dto);
    }
    validate(id) {
        return this.service.validatePeriod(id);
    }
    virementList(periodId, siteId) {
        return this.service.getVirementListBySite(periodId, siteId);
    }
};
exports.PayrollController = PayrollController;
__decorate([
    (0, common_1.Post)('periods'),
    (0, roles_decorator_1.Roles)(client_1.Role.COMPTABLE, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_period_dto_1.CreatePeriodDto, Object]),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "createPeriod", null);
__decorate([
    (0, common_1.Get)('periods'),
    (0, roles_decorator_1.Roles)(client_1.Role.COMPTABLE, client_1.Role.ADMIN),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "listPeriods", null);
__decorate([
    (0, common_1.Get)('periods/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.COMPTABLE, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "getPeriod", null);
__decorate([
    (0, common_1.Patch)('lines/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.COMPTABLE, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, adjust_line_dto_1.AdjustLineDto]),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "adjustLine", null);
__decorate([
    (0, common_1.Post)('periods/:id/validate'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "validate", null);
__decorate([
    (0, common_1.Get)('periods/:periodId/site/:siteId/virements'),
    (0, roles_decorator_1.Roles)(client_1.Role.COMPTABLE, client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('periodId')),
    __param(1, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PayrollController.prototype, "virementList", null);
exports.PayrollController = PayrollController = __decorate([
    (0, common_1.Controller)('payroll'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [payroll_service_1.PayrollService])
], PayrollController);
//# sourceMappingURL=payroll.controller.js.map