import {
  Controller,
  Post,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  Req,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { UploadService } from './upload.service';
import { Request } from 'express';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';

@Controller('upload')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  /**
   * Upload photo pointage / incident.
   * Stockage dual :
   * 1) data URL base64 → persistant en DB (Render free = disque éphémère)
   * 2) fichier local /uploads → utile en local + URL HTTPS si PUBLIC_API_URL
   */
  @Post('photo')
  @Roles(Role.CHEF, Role.ADMIN, Role.AGENT, Role.MAGASINIER)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^image\/(jpeg|jpg|png|webp)$/)) {
          return cb(
            new BadRequestException(
              'Seules les images JPEG/PNG/WebP sont acceptées',
            ) as any,
            false,
          );
        }
        cb(null, true);
      },
    }),
  )
  uploadPhoto(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Aucun fichier envoyé (champ: file)');
    }

    const mime = file.mimetype || 'image/jpeg';
    const base64 = file.buffer.toString('base64');
    // Data URL = source de vérité pour l'historique (survit aux redémarrages Render)
    const dataUrl = `data:${mime};base64,${base64}`;

    // Copie locale optionnelle (dev / si volume monté)
    let publicUrl: string | null = null;
    try {
      const dir = this.uploadService.uploadDir;
      if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
      const filename = this.uploadService.uniqueName(file.originalname || 'photo.jpg');
      writeFileSync(join(dir, filename), file.buffer);
      const host = req.get('host');
      publicUrl = this.uploadService.buildPublicUrl(filename, host);
    } catch {
      // ignore disk errors on free tier
    }

    return {
      // Priorité au data URL pour persistance DB
      url: dataUrl,
      fileUrl: publicUrl,
      size: file.size,
      mimetype: mime,
    };
  }
}
