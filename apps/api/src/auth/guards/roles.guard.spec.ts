import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { RolesGuard } from './roles.guard';
describe('Admin authorization', () => {
  const reflector = {
    getAllAndOverride: jest.fn().mockReturnValue([Role.ADMIN]),
  };
  const guard = new RolesGuard(reflector as unknown as Reflector);
  const context = (role?: Role) =>
    ({
      getHandler: () => {},
      getClass: () => {},
      switchToHttp: () => ({
        getRequest: () => ({ user: role ? { role } : undefined }),
      }),
    }) as unknown as ExecutionContext;
  it('rejects readers and missing users', () => {
    expect(guard.canActivate(context(Role.USER))).toBe(false);
    expect(guard.canActivate(context())).toBe(false);
  });
  it('permits administrators', () => {
    expect(guard.canActivate(context(Role.ADMIN))).toBe(true);
  });
});
