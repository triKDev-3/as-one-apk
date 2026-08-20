export declare class UploadService {
    readonly uploadDir: string;
    constructor();
    buildPublicUrl(filename: string, reqHost?: string): string;
    uniqueName(originalName: string): string;
}
