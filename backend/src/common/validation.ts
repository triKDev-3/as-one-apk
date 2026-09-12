import {
  BadRequestException,
  ValidationError,
  ValidationPipe,
} from '@nestjs/common';

function flattenValidationErrors(
  errors: ValidationError[],
  parent = '',
): string[] {
  const out: string[] = [];
  for (const e of errors) {
    const path = parent ? `${parent}.${e.property}` : e.property;
    if (e.constraints) {
      out.push(...Object.values(e.constraints));
    }
    if (e.children?.length) {
      out.push(...flattenValidationErrors(e.children, path));
    }
  }
  return out;
}

/** Pipe global : whitelist, types, messages FR. */
export function createAppValidationPipe() {
  return new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
    transformOptions: { enableImplicitConversion: true },
    exceptionFactory: (errors: ValidationError[]) => {
      const messages = flattenValidationErrors(errors);
      return new BadRequestException({
        statusCode: 400,
        error: 'Bad Request',
        message: messages[0] || 'Données invalides',
        errors: messages,
      });
    },
  });
}
