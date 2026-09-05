import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  handleRequest(err: any, user: any, info: any) {
    // If error or no user, just return null (no user attached)
    // This allows the route to proceed even if no valid token is provided
    return user || null;
  }
}
