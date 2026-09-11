import { ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Un chef en mode « toutes les activités » peut CONSULTER n'importe quel site,
 * mais ne peut PAS y faire d'opération s'il n'y est pas affecté.
 * L'admin a toujours le droit d'agir.
 */
export async function assertCanOperateOnSite(
  prisma: PrismaService,
  siteId: string,
  userId: string,
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true },
  });
  if (!user) throw new ForbiddenException('Utilisateur introuvable');
  if (user.role === 'ADMIN') return;
  if (user.role !== 'CHEF') return;

  const link = await prisma.siteChef.findUnique({
    where: { siteId_chefId: { siteId, chefId: userId } },
  });
  if (!link) {
    throw new ForbiddenException(
      "Vous n'êtes pas affecté à ce site. Consultation uniquement.",
    );
  }
}
