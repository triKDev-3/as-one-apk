import { PointageService } from './pointage.service';
import { CreatePointageDto } from './dto/create-pointage.dto';
export declare class PointageController {
    private readonly service;
    constructor(service: PointageService);
    create(dto: CreatePointageDto, req: any): Promise<any>;
    list(siteId?: string, date?: string, type?: string): any;
    getBySite(siteId: string, date?: string): any;
    getMyPointages(req: any): any;
}
