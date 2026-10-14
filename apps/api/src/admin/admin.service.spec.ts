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

describe('Dashboard engagement and administrator roster', () => {
  afterEach(() => jest.useRealTimers());
  it('queries all ADMIN accounts independently of the recent-signup limit', async () => {
    const administrators = [{ id: 'older-admin', role: 'ADMIN' }];
    const prisma = {
      user: { findMany: jest.fn().mockResolvedValue(administrators) },
    };
    expect(await new AdminService(prisma as any).getAdministrators()).toEqual(
      administrators,
    );
    expect(prisma.user.findMany).toHaveBeenCalledWith({
      where: { role: 'ADMIN' },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        username: true,
        email: true,
        createdAt: true,
        role: true,
      },
    });
  });
  it('counts distinct weekly readers and only valid positive recorded time in the seven-day window', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-10-14T12:00:00Z'));
    const prisma = {
      user: {
        count: jest.fn().mockResolvedValue(0),
        findMany: jest.fn().mockImplementation(({ select }) =>
          Promise.resolve(
            select.readingStats
              ? [
                  {
                    readingStats: {
                      '2026-10-08': 60000,
                      '2026-10-14': 120000,
                      '2026-10-07': 999999,
                      '2026-10-15': 999999,
                      '2026-10-13': Number.MAX_VALUE,
                      '2026-10-12': '60000',
                      bad: 999999,
                    },
                  },
                  { readingStats: null },
                  { readingStats: [] },
                ]
              : [],
          ),
        ),
      },
      historyEntry: {
        count: jest.fn().mockResolvedValue(0),
        groupBy: jest
          .fn()
          .mockResolvedValue([{ userId: 'a' }, { userId: 'b' }]),
      },
      comment: { count: jest.fn().mockResolvedValue(0) },
      libraryEntry: { count: jest.fn().mockResolvedValue(0) },
      pushDevice: { groupBy: jest.fn().mockResolvedValue([]) },
      sourceHealth: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const result = await new AdminService(prisma as any).getAnalytics();
    expect(result.engagement).toEqual({
      onboardedUsers: 0,
      weeklyActiveReaders: 2,
      readingMinutes7Days: 3,
    });
    expect(prisma.historyEntry.groupBy).toHaveBeenCalledWith({
      by: ['userId'],
      where: {
        deletedAt: null,
        lastReadAt: {
          gte: new Date('2026-10-08T00:00:00Z'),
          lte: new Date('2026-10-14T12:00:00Z'),
        },
      },
    });
    expect(prisma.user.count).toHaveBeenCalledWith({
      where: { isOnboarded: true },
    });
  });
});
