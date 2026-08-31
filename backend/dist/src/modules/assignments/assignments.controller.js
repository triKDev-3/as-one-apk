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
exports.AssignmentsController = void 0;
const common_1 = require("@nestjs/common");
const assignments_service_1 = require("./assignments.service");
const create_assignment_dto_1 = require("./dto/create-assignment.dto");
const respond_assignment_dto_1 = require("./dto/respond-assignment.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let AssignmentsController = class AssignmentsController {
    constructor(service) {
        this.service = service;
    }
    create(dto, req) {
        return this.service.create(dto, req.user.id);
    }
    pendingTransfers(req) {
        return this.service.listPendingTransfers(req.user.id);
    }
    listChefs() {
        return this.service.listChefs();
    }
    getBySite(siteId) {
        return this.service.getBySite(siteId);
    }
    getAvailableAgents(siteId) {
        return this.service.getAvailableAgents(siteId);
    }
    releaseAgent(id, req) {
        return this.service.releaseAgent(id, req.user.id);
    }
    resolveTransfer(id, accept, req) {
        return this.service.resolveTransfer(id, req.user.id, accept);
    }
    respond(id, dto, req) {
        return this.service.confirmOrRefuse(id, req.user.id, dto.accept);
    }
    requestTransfer(id, toChefId, req) {
        return this.service.requestTransfer(id, req.user.id, toChefId);
    }
};
exports.AssignmentsController = AssignmentsController;
__decorate([
    (0, common_1.Post)(),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_assignment_dto_1.CreateAssignmentDto, Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "create", null);
__decorate([
    (0, common_1.Get)('transfers/pending'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "pendingTransfers", null);
__decorate([
    (0, common_1.Get)('chefs'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "listChefs", null);
__decorate([
    (0, common_1.Get)('site/:siteId'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "getBySite", null);
__decorate([
    (0, common_1.Get)('agents/available'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Query)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "getAvailableAgents", null);
__decorate([
    (0, common_1.Patch)(':id/release'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "releaseAgent", null);
__decorate([
    (0, common_1.Patch)('transfers/:id/resolve'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('accept')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Boolean, Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "resolveTransfer", null);
__decorate([
    (0, common_1.Patch)(':id/respond'),
    (0, roles_decorator_1.Roles)(client_1.Role.AGENT),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, respond_assignment_dto_1.RespondAssignmentDto, Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "respond", null);
__decorate([
    (0, common_1.Post)(':id/transfer'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('toChefId')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], AssignmentsController.prototype, "requestTransfer", null);
exports.AssignmentsController = AssignmentsController = __decorate([
    (0, common_1.Controller)('assignments'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [assignments_service_1.AssignmentsService])
], AssignmentsController);
//# sourceMappingURL=assignments.controller.js.map