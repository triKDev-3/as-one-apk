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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MaterialReturnDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class MaterialReturnDto {
}
exports.MaterialReturnDto = MaterialReturnDto;
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "siteId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "itemId", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], MaterialReturnDto.prototype, "quantity", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.MaterialState),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "state", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.RetentionTarget),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "retentionTarget", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "agentId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], MaterialReturnDto.prototype, "notes", void 0);
//# sourceMappingURL=material-return.dto.js.map