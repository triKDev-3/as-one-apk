import { Injectable, ConflictException, NotFoundException, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateProfileDto, ChangePasswordDto } from './dto/update-profile.dto';
import * as bcrypt from 'bcrypt';
import { Role, AgentType } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUserDto) {
    const existing = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
    if (existing) {
      throw new ConflictException('Ce numéro de téléphone est déjà utilisé');
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
        agentType: dto.role === Role.AGENT ? (dto.agentType || AgentType.TEMPORAIRE) : null,
        mobileMoneyOperator: dto.mobileMoneyOperator,
        agentProfile: dto.role === Role.AGENT ? {
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

  async findAll(role?: Role) {
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

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { agentProfile: true },
    });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    return user;
  }

  /**
   * Protection : impossible de désactiver le dernier admin actif
   * (évite de se verrouiller hors de l'application).
   */
  async setActive(id: string, isActive: boolean) {
    const target = await this.prisma.user.findUnique({ where: { id } });
    if (!target) throw new NotFoundException('Utilisateur introuvable');

    if (!isActive && target.role === Role.ADMIN && target.isActive) {
      const activeAdmins = await this.prisma.user.count({
        where: { role: Role.ADMIN, isActive: true },
      });
      if (activeAdmins <= 1) {
        throw new BadRequestException(
          'Impossible de désactiver le dernier administrateur actif. '
          + 'Créez un autre compte ADMIN avant, ou réactivez-le via la base de données.',
        );
      }
    }

    return this.prisma.user.update({
      where: { id },
      data: { isActive },
      select: { id: true, isActive: true, firstName: true, lastName: true, role: true },
    });
  }

  async updateRole(id: string, newRole: Role) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('Utilisateur introuvable');
    if (user.role === Role.ADMIN) {
      throw new BadRequestException("Impossible de modifier le rôle d'un admin");
    }

    if (newRole === Role.AGENT && user.role !== Role.AGENT) {
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

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    if (dto.phone) {
      const existing = await this.prisma.user.findFirst({
        where: { phone: dto.phone, NOT: { id: userId } },
      });
      if (existing) {
        throw new ConflictException('Ce numéro est déjà utilisé');
      }
    }

    let operator = dto.mobileMoneyOperator;
    if (dto.phone && !operator) {
      const digits = dto.phone.replace(/\D/g, '');
      if (digits.includes('90') || digits.includes('91')) operator = 'TMoney';
      else if (digits.includes('97') || digits.includes('96')) operator = 'Flooz';
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

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException();

    const valid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Mot de passe actuel incorrect');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 12);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    return { ok: true };
  }

  async adminResetPassword(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Utilisateur introuvable');

    const passwordHash = await bcrypt.hash('asone123', 12);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    return { ok: true, message: 'Mot de passe réinitialisé' };
  }
}
