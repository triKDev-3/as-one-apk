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
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma/prisma.service");
const bcrypt = require("bcrypt");
const client_1 = require("@prisma/client");
let UsersService = class UsersService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async create(dto) {
        const existing = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
        if (existing) {
            throw new common_1.ConflictException('Ce numéro de téléphone est déjà utilisé');
        }
        const passwordToUse = dto.password || 'asone123';
        const passwordHash = await bcrypt.hash(passwordToUse, 12);
        const user = await this.prisma.user.create({
            data: {
                phone: dto.phone,
                email: dto.email,
                passwordHash,
                firstName: dto.firstName,
                lastName: dto.lastName,
                role: dto.role,
                agentType: dto.role === client_1.Role.AGENT ? (dto.agentType || client_1.AgentType.TEMPORAIRE) : null,
                mobileMoneyOperator: dto.mobileMoneyOperator,
                agentProfile: dto.role === client_1.Role.AGENT ? {
                    create: { isAvailable: true },
                } : undefined,
            },
            select: {
                id: true,
                phone: true,
                firstName: true,
                lastName: true,
                role: true,
                agentType: true,
                isActive: true,
                createdAt: true,
            },
        });
        return user;
    }
    async findAll(role) {
        return this.prisma.user.findMany({
            where: role ? { role } : undefined,
            select: {
                id: true,
                phone: true,
                firstName: true,
                lastName: true,
                role: true,
                agentType: true,
                isActive: true,
                rankingScore: true,
                agentProfile: { select: { isAvailable: true } },
            },
            orderBy: { lastName: 'asc' },
        });
    }
    async findOne(id) {
        const user = await this.prisma.user.findUnique({
            where: { id },
            include: { agentProfile: true },
        });
        if (!user)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        return user;
    }
    async setActive(id, isActive) {
        const target = await this.prisma.user.findUnique({ where: { id } });
        if (!target)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        if (!isActive && target.role === client_1.Role.ADMIN && target.isActive) {
            const activeAdmins = await this.prisma.user.count({
                where: { role: client_1.Role.ADMIN, isActive: true },
            });
            if (activeAdmins <= 1) {
                throw new common_1.BadRequestException('Impossible de désactiver le dernier administrateur actif. '
                    + 'Créez un autre compte ADMIN avant, ou réactivez-le via la base de données.');
            }
        }
        return this.prisma.user.update({
            where: { id },
            data: { isActive },
            select: { id: true, isActive: true, firstName: true, lastName: true, role: true },
        });
    }
    async updateRole(id, newRole) {
        const user = await this.prisma.user.findUnique({ where: { id } });
        if (!user)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        if (user.role === client_1.Role.ADMIN) {
            throw new common_1.BadRequestException("Impossible de modifier le rôle d'un admin");
        }
        if (newRole === client_1.Role.AGENT && user.role !== client_1.Role.AGENT) {
            const existingProfile = await this.prisma.agentProfile.findUnique({ where: { userId: id } });
            if (!existingProfile) {
                await this.prisma.agentProfile.create({
                    data: { userId: id, isAvailable: true }
                });
            }
        }
        return this.prisma.user.update({
            where: { id },
            data: { role: newRole },
            select: { id: true, role: true, firstName: true, lastName: true },
        });
    }
    async updateProfile(userId, dto) {
        if (dto.phone) {
            const existing = await this.prisma.user.findFirst({
                where: { phone: dto.phone, NOT: { id: userId } },
            });
            if (existing) {
                throw new common_1.ConflictException('Ce numéro est déjà utilisé');
            }
        }
        let operator = dto.mobileMoneyOperator;
        if (dto.phone && !operator) {
            const digits = dto.phone.replace(/\D/g, '');
            if (digits.includes('90') || digits.includes('91'))
                operator = 'TMoney';
            else if (digits.includes('97') || digits.includes('96'))
                operator = 'Flooz';
        }
        return this.prisma.user.update({
            where: { id: userId },
            data: {
                ...(dto.firstName ? { firstName: dto.firstName } : {}),
                ...(dto.lastName ? { lastName: dto.lastName } : {}),
                ...(dto.phone ? { phone: dto.phone } : {}),
                ...(operator ? { mobileMoneyOperator: operator } : {}),
            },
            select: {
                id: true,
                firstName: true,
                lastName: true,
                phone: true,
                mobileMoneyOperator: true,
                role: true,
            },
        });
    }
    async changePassword(userId, dto) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user)
            throw new common_1.NotFoundException();
        const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
        if (!valid) {
            throw new common_1.UnauthorizedException('Mot de passe actuel incorrect');
        }
        const passwordHash = await bcrypt.hash(dto.newPassword, 12);
        await this.prisma.user.update({
            where: { id: userId },
            data: { passwordHash },
        });
        return { ok: true };
    }
    async adminResetPassword(userId) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (!user)
            throw new common_1.NotFoundException('Utilisateur introuvable');
        const passwordHash = await bcrypt.hash('asone123', 12);
        await this.prisma.user.update({
            where: { id: userId },
            data: { passwordHash },
        });
        return { ok: true, message: 'Mot de passe réinitialisé' };
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], UsersService);
//# sourceMappingURL=users.service.js.map