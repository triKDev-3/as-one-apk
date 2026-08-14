import { Injectable } from '@nestjs/common';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { randomBytes } from 'crypto';

@Injectable()
export class UploadService {
  readonly uploadDir = join(process.cwd(), 'uploads');

  constructor() {
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Génère un nom de fichier unique et retourne l'URL relative.
   * En prod, remplacer par Cloudinary si CLOUDINARY_URL est défini.
   */
  buildPublicUrl(filename: string, reqHost?: string): string {
    const base =
      process.env.PUBLIC_API_URL ||
      (reqHost ? `http://${reqHost}` : 'http://localhost:3000');
    return `${base}/uploads/${filename}`;
  }

  uniqueName(originalName: string): string {
    const ext = originalName.includes('.')
      ? originalName.slice(originalName.lastIndexOf('.'))
      : '.jpg';
    return `${Date.now()}-${randomBytes(6).toString('hex')}${ext}`;
  }
}
