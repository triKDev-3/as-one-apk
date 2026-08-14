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
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { UploadService } from './upload.service';
import { Request } from 'express';

@Controller('upload')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('photo')
  @Roles(Role.CHEF, Role.ADMIN, Role.AGENT, Role.MAGASINIER)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (_req, file, cb) => {
          const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `${unique}${extname(file.originalname) || '.jpg'}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 }, // 5 Mo
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^image\/(jpeg|jpg|png|webp)$/)) {
          return cb(
            new BadRequestException('Seules les images JPEG/PNG/WebP sont acceptées') as any,
            false,
          );
        }
        cb(null, true);
      },
    }),
  )
  uploadPhoto(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('Aucun fichier envoyé (champ: file)');
    }

    const host = req.get('host');
    const url = this.uploadService.buildPublicUrl(file.filename, host);

    return {
      url,
      filename: file.filename,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}
