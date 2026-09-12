import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { Reflector } from '@nestjs/core';
import { TRANSACTION_KEY } from '../decorators/transaction.decorator';
import { PrismaService } from '../../modules/prisma/prisma.service';

@Injectable()
export class TransactionInterceptor implements NestInterceptor {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const transactionOptions = this.reflector.get(
      TRANSACTION_KEY,
      context.getHandler(),
    );

    if (!transactionOptions) {
      return next.handle();
    }

    // Transaction will be handled by the service method itself
    // This interceptor is here for future enhanced transaction management
    return next.handle();
  }
}
