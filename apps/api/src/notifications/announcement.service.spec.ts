import { AnnouncementService } from './announcement.service';
import { AnnouncementsController } from './announcements.controller';
import { AdminController } from '../admin/admin.controller';
import { GUARDS_METADATA } from '@nestjs/common/constants';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';

describe('Admin system messages', () => {
  const prisma = {
    systemAnnouncement: {
      create: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    pushDevice: { findMany: jest.fn() },
    user: { findMany: jest.fn() },
  };
  const notifications = { create: jest.fn() };
  const service = new AnnouncementService(prisma as any, notifications as any);
  beforeEach(() => jest.resetAllMocks());
  it('keeps announcement and administrator endpoints behind JWT and ADMIN authorization', () => {
    for (const controller of [AnnouncementsController, AdminController]) {
      expect(Reflect.getMetadata('roles', controller)).toEqual(['ADMIN']);
      expect(Reflect.getMetadata(GUARDS_METADATA, controller)).toEqual([
        JwtAuthGuard,
        RolesGuard,
      ]);
    }
  });
  it('rejects malformed inputs instead of throwing runtime type errors', async () => {
    for (const input of [
      null,
      {},
      { title: 1 },
      { title: 'Notice', body: {}, publishAt: '2026-10-14' },
    ]) {
      await expect(service.create(input as any)).rejects.toMatchObject({
        status: 400,
      });
    }
    expect(prisma.systemAnnouncement.create).not.toHaveBeenCalled();
  });
  it('does not allow supplied publication state or identifiers to bypass delivery', async () => {
    const input = {
      title: ' Notice ',
      body: ' Message ',
      severity: 'INFO',
      pushEnabled: false,
      publishAt: '2099-01-01T00:00:00Z',
      id: 'forged',
      publishedAt: new Date(),
    };
    prisma.systemAnnouncement.create.mockResolvedValue({
      publishAt: new Date(input.publishAt),
    });
    await service.create(input as any);
    const data = prisma.systemAnnouncement.create.mock.calls[0][0].data;
    expect(data.title).toBe('Notice');
    expect(data.body).toBe('Message');
    expect(data).not.toHaveProperty('publishedAt');
    expect(data).not.toHaveProperty('id');
  });
  it('delivers unfiltered messages to every registered user, including users without push devices', async () => {
    prisma.systemAnnouncement.findMany.mockResolvedValue([
      {
        id: 'message',
        title: 'Notice',
        body: 'Message',
        severity: 'INFO',
        pushEnabled: false,
      },
    ]);
    prisma.pushDevice.findMany.mockResolvedValue([]);
    prisma.user.findMany.mockResolvedValue([{ id: 'reader' }, { id: 'admin' }]);
    await service.publishDue();
    expect(
      notifications.create.mock.calls.map(([input]) => input.userId),
    ).toEqual(['reader', 'admin']);
    expect(notifications.create).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'SYSTEM_ANNOUNCEMENT', push: false }),
    );
    expect(prisma.systemAnnouncement.update).toHaveBeenCalledWith({
      where: { id: 'message' },
      data: { publishedAt: expect.any(Date) },
    });
  });
  it('returns a bounded, newest-first announcement history', async () => {
    prisma.systemAnnouncement.findMany.mockResolvedValue([]);
    await service.list();
    expect(prisma.systemAnnouncement.findMany).toHaveBeenCalledWith({
      orderBy: { createdAt: 'desc' },
      take: 25,
    });
  });
});
