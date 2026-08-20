export declare class HealthController {
    root(): {
        name: string;
        status: string;
        version: string;
        time: string;
    };
    health(): {
        status: string;
    };
}
