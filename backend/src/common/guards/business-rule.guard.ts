import {
  Injectable,
  CanActivate,
  ExecutionContext,
  BadRequestException,
} from '@nestjs/common';
import { AssignmentValidator } from '../validators/assignment.validator';

@Injectable()
export class BusinessRuleGuard implements CanActivate {
  constructor(private validator: AssignmentValidator) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const { assignmentId } = request.params || request.body;

    if (!assignmentId) {
      return true; // No assignment ID, skip validation
    }

    try {
      // Validate not locked
      await this.validator.validateNotLocked(assignmentId);

      // Validate pending status
      await this.validator.validatePendingStatus(assignmentId);

      return true;
    } catch (error) {
      throw new BadRequestException(
        error.message || 'Business rule validation failed',
      );
    }
  }
}
