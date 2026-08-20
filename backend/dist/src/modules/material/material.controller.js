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
exports.MaterialController = void 0;
const common_1 = require("@nestjs/common");
const material_service_1 = require("./material.service");
const create_item_dto_1 = require("./dto/create-item.dto");
const material_out_dto_1 = require("./dto/material-out.dto");
const material_return_dto_1 = require("./dto/material-return.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let MaterialController = class MaterialController {
    constructor(service) {
        this.service = service;
    }
    createItem(dto) {
        return this.service.createItem(dto);
    }
    listItems(category) {
        return this.service.listItems(category);
    }
    materialOut(dto, req) {
        return this.service.materialOut(dto, req.user.id);
    }
    materialReturn(dto, req) {
        return this.service.materialReturn(dto, req.user.id);
    }
    getBySite(siteId) {
        return this.service.getMovementsBySite(siteId);
    }
    createAlert(body) {
        return this.service.createVehicleAlert(body);
    }
    getAlerts() {
        return this.service.getActiveAlerts();
    }
};
exports.MaterialController = MaterialController;
__decorate([
    (0, common_1.Post)('items'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_item_dto_1.CreateMaterialItemDto]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "createItem", null);
__decorate([
    (0, common_1.Get)('items'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER, client_1.Role.CHEF),
    __param(0, (0, common_1.Query)('category')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "listItems", null);
__decorate([
    (0, common_1.Post)('out'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [material_out_dto_1.MaterialOutDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "materialOut", null);
__decorate([
    (0, common_1.Post)('return'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [material_return_dto_1.MaterialReturnDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "materialReturn", null);
__decorate([
    (0, common_1.Get)('site/:siteId'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.CHEF, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('siteId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "getBySite", null);
__decorate([
    (0, common_1.Post)('vehicle-alerts'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "createAlert", null);
__decorate([
    (0, common_1.Get)('vehicle-alerts'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER, client_1.Role.COMPTABLE),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "getAlerts", null);
exports.MaterialController = MaterialController = __decorate([
    (0, common_1.Controller)('material'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [material_service_1.MaterialService])
], MaterialController);
//# sourceMappingURL=material.controller.js.map