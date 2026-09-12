import { SetMetadata } from '@nestjs/common';

export const TRANSACTION_KEY = 'transaction';

export interface TransactionOptions {
  maxWait?: number;
  timeout?: number;
}

/**
 * Decorator to mark methods that should run in a Prisma transaction
 * Usage: @Transactional({ maxWait: 5000, timeout: 10000 })
 */
export const Transactional = (options?: TransactionOptions) =>
  SetMetadata(TRANSACTION_KEY, options || {});
