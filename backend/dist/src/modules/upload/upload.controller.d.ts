import { UploadService } from './upload.service';
import { Request } from 'express';
export declare class UploadController {
    private readonly uploadService;
    constructor(uploadService: UploadService);
    uploadPhoto(file: Express.Multer.File, req: Request): {
        url: string;
        filename: string;
        size: number;
        mimetype: string;
    };
}
