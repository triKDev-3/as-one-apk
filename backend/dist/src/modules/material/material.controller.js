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
const create_alert_dto_1 = require("./dto/create-alert.dto");
const fiche_dto_1 = require("./dto/fiche.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let MaterialController = class MaterialController {
    constructor(service) {
        this.service = service;
    }
    seedCatalog() {
        return this.service.ensureDefaultCatalog();
    }
    createItem(dto) {
        return this.service.createItem(dto);
    }
    updateItem(id, dto) {
        return this.service.updateItem(id, dto);
    }
    listItems(category, all) {
        return this.service.listItems(category, all === 'true');
    }
    createFiche(dto, req) {
        return this.service.createFiche(dto, req.user.id, req.user.role);
    }
    listFiches(siteId, status, req) {
        return this.service.listFiches({
            siteId,
            status,
            userId: req.user.id,
            role: req.user.role,
        });
    }
    getFiche(id) {
        return this.service.getFiche(id);
    }
    updateFiche(id, dto, req) {
        return this.service.updateFiche(id, dto, req.user.id);
    }
    deliver(id, req) {
        return this.service.deliverFiche(id, req.user.id);
    }
    checkReturn(id, dto, req) {
        return this.service.checkReturn(id, dto, req.user.id);
    }
    close(id, req) {
        return this.service.closeFiche(id, req.user.id);
    }
    damages() {
        return this.service.listDamages();
    }
    sanction(dto, req) {
        return this.service.applySanction(dto, req.user.id);
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
    (0, common_1.Post)('items/seed'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "seedCatalog", null);
__decorate([
    (0, common_1.Post)('items'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_item_dto_1.CreateMaterialItemDto]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "createItem", null);
__decorate([
    (0, common_1.Patch)('items/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, create_item_dto_1.UpdateMaterialItemDto]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "updateItem", null);
__decorate([
    (0, common_1.Get)('items'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER, client_1.Role.CHEF),
    __param(0, (0, common_1.Query)('category')),
    __param(1, (0, common_1.Query)('all')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "listItems", null);
__decorate([
    (0, common_1.Post)('fiches'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [fiche_dto_1.CreateMaterialFicheDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "createFiche", null);
__decorate([
    (0, common_1.Get)('fiches'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.MAGASINIER, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Query)('siteId')),
    __param(1, (0, common_1.Query)('status')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "listFiches", null);
__decorate([
    (0, common_1.Get)('fiches/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.CHEF, client_1.Role.MAGASINIER, client_1.Role.ADMIN, client_1.Role.COMPTABLE),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "getFiche", null);
__decorate([
    (0, common_1.Patch)('fiches/:id'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, fiche_dto_1.UpdateMaterialFicheDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "updateFiche", null);
__decorate([
    (0, common_1.Post)('fiches/:id/deliver'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "deliver", null);
__decorate([
    (0, common_1.Post)('fiches/:id/return'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, fiche_dto_1.CheckReturnDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "checkReturn", null);
__decorate([
    (0, common_1.Post)('fiches/:id/close'),
    (0, roles_decorator_1.Roles)(client_1.Role.MAGASINIER, client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "close", null);
__decorate([
    (0, common_1.Get)('damages'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MAGASINIER, client_1.Role.COMPTABLE),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "damages", null);
__decorate([
    (0, common_1.Post)('sanctions'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [fiche_dto_1.ApplySanctionDto, Object]),
    __metadata("design:returntype", void 0)
], MaterialController.prototype, "sanction", null);
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
    __metadata("design:paramtypes", [create_alert_dto_1.CreateVehicleAlertDto]),
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