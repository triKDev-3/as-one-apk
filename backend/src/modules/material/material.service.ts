import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateMaterialItemDto } from './dto/create-item.dto';
import { MaterialOutDto } from './dto/material-out.dto';
import { MaterialReturnDto } from './dto/material-return.dto';
import { MaterialState, RetentionTarget } from '@prisma/client';
import { randomBytes } from 'crypto';

@Injectable()
export class MaterialService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------- Catalogue matériel ----------
  async createItem(dto: CreateMaterialItemDto) {
    return this.prisma.materialItem.create({
      data: {
        name: dto.name,
        category: dto.category,
        unitPrice: dto.unitPrice,
      },
    });
  }

  async listItems(category?: string) {
    return this.prisma.materialItem.findMany({
      where: {
        isActive: true,
        ...(category ? { category } : {}),
      },
      orderBy: { name: 'asc' },
    });
  }

  // ---------- Sortie de matériel (liée au chantier) ----------
  async materialOut(dto: MaterialOutDto, magasinierId: string) {
    const site = await this.prisma.site.findUnique({ where: { id: dto.siteId } });
    if (!site) throw new NotFoundException('Site introuvable');

    const item = await this.prisma.materialItem.findUnique({ where: { id: dto.itemId } });
    if (!item) throw new NotFoundException('Article introuvable');

    const printableRef = `MAT-${Date.now().toString(36).toUpperCase()}-${randomBytes(2).toString('hex').toUpperCase()}`;

    return this.prisma.materialMovement.create({
      data: {
        siteId: dto.siteId,
        itemId: dto.itemId,
        quantity: dto.quantity,
        type: 'OUT',
        notes: dto.notes,
        createdById: magasinierId,
        printableRef,
      },
      include: {
        item: true,
        site: { select: { id: true, name: true } },
      },
    });
  }

  // ---------- Retour + état + éventuelle retenue ----------
  async materialReturn(dto: MaterialReturnDto, magasinierId: string) {
    const outMovement = await this.prisma.materialMovement.findFirst({
      where: {
        siteId: dto.siteId,
        itemId: dto.itemId,
        type: 'OUT',
      },
      include: { item: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!outMovement) {
      throw new BadRequestException('Aucune sortie trouvée pour cet article sur ce site');
    }

    // Création du mouvement de retour
    const returnMovement = await this.prisma.materialMovement.create({
      data: {
        siteId: dto.siteId,
        itemId: dto.itemId,
        quantity: dto.quantity,
        type: 'RETURN',
        state: dto.state,
        notes: dto.notes,
        createdById: magasinierId,
        printableRef: outMovement.printableRef,
      },
      include: { item: true },
    });

    // Si DEGRADE ou MANQUANT → créer la retenue immédiatement
    if (dto.state === MaterialState.DEGRADE || dto.state === MaterialState.MANQUANT) {
      if (!dto.retentionTarget) {
        throw new BadRequestException('Une cible de retenue est obligatoire (ONE_AGENT ou WHOLE_GROUP)');
      }

      const unitPrice = Number(outMovement.item.unitPrice);
      let amount = unitPrice * dto.quantity;

      if (dto.retentionTarget === RetentionTarget.WHOLE_GROUP) {
        // On divise plus tard au moment de l’application sur les agents pointés
        // Ici on stocke le montant total
      }

      if (dto.retentionTarget === RetentionTarget.ONE_AGENT && !dto.agentId) {
        throw new BadRequestException('agentId obligatoire pour une retenue individuelle');
      }

      await this.prisma.materialRetention.create({
        data: {
          movementId: returnMovement.id,
          target: dto.retentionTarget,
          agentId: dto.agentId || null,
          amount,
          isApplied: true, // créée immédiatement selon le cahier des charges
        },
      });
    }

    return returnMovement;
  }

  // ---------- Historique par chantier ----------
  async getMovementsBySite(siteId: string) {
    return this.prisma.materialMovement.findMany({
      where: { siteId },
      include: {
        item: true,
        retention: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // ---------- Alertes véhicules ----------
  async createVehicleAlert(data: {
    vehicleName: string;
    alertType: string;
    lastDate: string;
    validityDays: number;
  }) {
    const lastDate = new Date(data.lastDate);
    const nextDueDate = new Date(lastDate);
    nextDueDate.setDate(nextDueDate.getDate() + data.validityDays);

    return this.prisma.vehicleAlert.create({
      data: {
        vehicleName: data.vehicleName,
        alertType: data.alertType,
        lastDate,
        validityDays: data.validityDays,
        nextDueDate,
      },
    });
  }

  async getActiveAlerts() {
    const now = new Date();
    const in7Days = new Date();
    in7Days.setDate(in7Days.getDate() + 7);

    return this.prisma.vehicleAlert.findMany({
      where: {
        isResolved: false,
        nextDueDate: { lte: in7Days },
      },
      orderBy: { nextDueDate: 'asc' },
    });
  }
}
