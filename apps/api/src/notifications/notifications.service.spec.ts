import { NotificationType } from '@prisma/client';
import { NotificationsService } from './notifications.service';

describe('NotificationsService', () => {
  const prisma = {
    notification: { findUnique: jest.fn(), create: jest.fn(), findMany: jest.fn(),
      findFirst: jest.fn(), updateMany: jest.fn(), deleteMany: jest.fn() },
    notificationPreference: { upsert: jest.fn() },
    pushDevice: { deleteMany: jest.fn(), create: jest.fn() },
    $transaction: jest.fn((fn) => fn(prisma)),
  };
  const push = { deliver: jest.fn() };
  const service = new NotificationsService(prisma as any, push as any);
  beforeEach(() => jest.clearAllMocks());

  it('deduplicates durable Inbox creation and push', async () => {
    const notification = { id: 'n1', userId: 'u1' };
    prisma.notification.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce(notification);
    prisma.notification.create.mockResolvedValue(notification);
    prisma.notificationPreference.upsert.mockResolvedValue({ commentReplies: true });
    const input = { userId: 'u1', type: NotificationType.COMMENT_REPLY,
      title: 'Reply', body: 'Open conversation', deepLink: 'keihatsu://inbox', dedupeKey: 'reply:c1' };
    await service.create(input);
    await service.create(input);
    expect(prisma.notification.create).toHaveBeenCalledTimes(1);
    expect(push.deliver).toHaveBeenCalledTimes(1);
  });

  it('stores an optional event when its push preference is off', async () => {
    prisma.notification.findUnique.mockResolvedValue(null);
    prisma.notification.create.mockResolvedValue({ id: 'n2' });
    prisma.notificationPreference.upsert.mockResolvedValue({ commentLikes: false });
    await service.create({ userId: 'u1', type: NotificationType.COMMENT_LIKE,
      title: 'Like', body: 'Like', deepLink: 'keihatsu://inbox', dedupeKey: 'like:c1' });
    expect(push.deliver).toHaveBeenCalledWith(expect.anything(), false);
  });

  it('scopes listing and mutations to the authenticated user', async () => {
    prisma.notification.findMany.mockResolvedValue([]);
    await service.list('owner', { category: 'COMMENTS', unread: 'true' });
    expect(prisma.notification.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ userId: 'owner', readAt: null }),
    }));
    prisma.notification.updateMany.mockResolvedValue({ count: 1 });
    await service.markRead('owner', 'n1');
    expect(prisma.notification.updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'n1', userId: 'owner', readAt: null },
    }));
    prisma.notification.deleteMany.mockResolvedValue({ count: 1 });
    await service.remove('owner', 'n1');
    expect(prisma.notification.deleteMany).toHaveBeenCalledWith({ where: { id: 'n1', userId: 'owner' } });
  });

  it('replaces token and installation ownership on registration', async () => {
    prisma.pushDevice.create.mockResolvedValue({ id: 'd1', installationId: 'install-1', platform: 'ANDROID', appVersion: '1.0', enabled: true });
    await service.registerDevice('new-user', 'install-1', 'ANDROID', 'token-1', '1.0');
    expect(prisma.pushDevice.deleteMany).toHaveBeenCalledWith({
      where: { OR: [{ installationId: 'install-1' }, { token: 'token-1' }] },
    });
    await service.unregisterDevice('new-user', 'install-1');
    expect(prisma.pushDevice.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'new-user', installationId: 'install-1' },
    });
  });
});
