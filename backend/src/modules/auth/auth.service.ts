import { Injectable, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { phone: dto.phone },
      include: { agentProfile: true },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Identifiants incorrects ou compte désactivé');
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Identifiants incorrects ou compte désactivé');
    }

    const payload = {
      sub: user.id,
      role: user.role,
      phone: user.phone,
    };

    const accessToken = this.jwt.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        role: user.role,
        agentType: user.agentType,
        isAvailable: user.agentProfile?.isAvailable ?? null,
        rankingScore: user.rankingScore,
      },
    };
  }

  async hashPassword(plain: string): Promise<string> {
    return bcrypt.hash(plain, 12);
  }

  async validateUser(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { agentProfile: true },
    });
    if (!user || !user.isActive) {
      throw new ForbiddenException('Compte inactif');
    }
    return user;
  }
}
