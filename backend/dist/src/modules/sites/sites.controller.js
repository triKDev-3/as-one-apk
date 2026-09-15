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
exports.SitesController = void 0;
const common_1 = require("@nestjs/common");
const sites_service_1 = require("./sites.service");
const create_site_dto_1 = require("./dto/create-site.dto");
const jwt_auth_guard_1 = require("../../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../../common/guards/roles.guard");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let SitesController = class SitesController {
    constructor(sitesService) {
        this.sitesService = sitesService;
    }
    create(dto, req) {
        return this.sitesService.create(dto, req.user.id);
    }
    findAll(req, type, all) {
        return this.sitesService.findAll(type, req.user.id, req.user.role, all === 'true');
    }
    findOne(id) {
        return this.sitesService.findOne(id);
    }
    assignChef(siteId, chefId) {
        return this.sitesService.assignChef(siteId, chefId);
    }
    removeChef(siteId, chefId) {
        return this.sitesService.removeChef(siteId, chefId);
    }
};
exports.SitesController = SitesController;
__decorate([
    (0, common_1.Post)(),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_site_dto_1.CreateSiteDto, Object]),
    __metadata("design:returntype", void 0)
], SitesController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.CHEF, client_1.Role.COMPTABLE, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('type')),
    __param(2, (0, common_1.Query)('all')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", void 0)
], SitesController.prototype, "findAll", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.CHEF, client_1.Role.COMPTABLE, client_1.Role.MAGASINIER),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], SitesController.prototype, "findOne", null);
__decorate([
    (0, common_1.Post)(':id/chefs/:chefId'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('chefId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], SitesController.prototype, "assignChef", null);
__decorate([
    (0, common_1.Delete)(':id/chefs/:chefId'),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('chefId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], SitesController.prototype, "removeChef", null);
exports.SitesController = SitesController = __decorate([
    (0, common_1.Controller)('sites'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    __metadata("design:paramtypes", [sites_service_1.SitesService])
], SitesController);
//# sourceMappingURL=sites.controller.js.map