import { AdminService } from './admin.service';
import { PrismaService } from '../prisma/prisma.service';
describe('Admin analytics', () => {
  it('uses non-deleted reading activity, safe user fields and enabled devices', async () => {
    const prisma = {
      user: {
        count: jest.fn().mockResolvedValue(5),
        findMany: jest.fn().mockResolvedValue([]),
      },
      historyEntry: {
        count: jest.fn().mockResolvedValue(12),
        groupBy: jest.fn().mockResolvedValue([{ userId: 'reader' }]),
      },
      comment: { count: jest.fn().mockResolvedValue(3) },
      libraryEntry: { count: jest.fn().mockResolvedValue(8) },
      pushDevice: {
        groupBy: jest
          .fn()
          .mockResolvedValue([{ platform: 'IOS', _count: { _all: 2 } }]),
      },
      sourceHealth: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const result = await new AdminService(
      prisma as unknown as PrismaService,
    ).getAnalytics();
    expect(result.activeReaders).toBe(1);
    expect(result.platforms).toEqual([{ platform: 'IOS', devices: 2 }]);
    expect(result.growth).toHaveLength(6);
    expect(prisma.historyEntry.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { lastReadAt: { gte: expect.any(Date) }, deletedAt: null },
      }),
    );
    expect(prisma.pushDevice.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { enabled: true, invalidatedAt: null },
      }),
    );
    expect(prisma.user.findMany.mock.calls[0][0].select).not.toHaveProperty(
      'password',
    );
  });
});
