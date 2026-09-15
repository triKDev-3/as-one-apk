"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const path_1 = require("path");
const app_module_1 = require("./app.module");
const validation_1 = require("./common/validation");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.useStaticAssets((0, path_1.join)(process.cwd(), 'uploads'), { prefix: '/uploads' });
    app.useGlobalPipes((0, validation_1.createAppValidationPipe)());
    app.enableCors({
        origin: true,
        credentials: true,
    });
    const port = process.env.PORT || 3000;
    await app.listen(port, '0.0.0.0');
    console.log(`🚀 AS ONE API running on http://0.0.0.0:${port}`);
}
bootstrap();
//# sourceMappingURL=main.js.map