import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType, Prisma, PushPlatform } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from './push.service';
import { notificationLinks } from './notification-links';

export const notificationCategories: Record<string, NotificationType[]> = {
  UPDATES: [NotificationType.CHAPTER_UPDATE],
  COMMENTS: [NotificationType.COMMENT_REPLY, NotificationType.COMMENT_MENTION,
    NotificationType.COMMENT_LIKE, NotificationType.COMMENT_MODERATION],
  SYSTEM: [NotificationType.SYSTEM_ANNOUNCEMENT, NotificationType.SOURCE_OUTAGE,
    NotificationType.SOURCE_RESTORED],
  ACCOUNT: [NotificationType.APP_UPDATE_REQUIRED, NotificationType.ACCOUNT_SECURITY,
    NotificationType.SYNC_FAILURE],
};

export type NotificationInput = {
  userId: string; type: NotificationType; title: string; body: string;
  deepLink: string; dedupeKey: string; groupingKey?: string;
  actorUserId?: string; sourceId?: string; mangaId?: string;
  chapterId?: string; commentId?: string; threadId?: string;
  data?: Prisma.InputJsonValue; push?: boolean; expiresAt?: Date;
};

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService, private push: PushService) {}

  async create(input: NotificationInput) {
    const existing = await this.prisma.notification.findUnique({
      where: { userId_dedupeKey: { userId: input.userId, dedupeKey: input.dedupeKey } },
    });
    if (existing) return existing;
    let notification;
    try {
      notification = await this.prisma.notification.create({ data: {
        userId: input.userId, type: input.type, title: input.title.slice(0, 160),
        body: input.body.slice(0, 500), deepLink: input.deepLink,
        dedupeKey: input.dedupeKey, groupingKey: input.groupingKey,
        actorUserId: input.actorUserId, sourceId: input.sourceId, mangaId: input.mangaId,
        chapterId: input.chapterId, commentId: input.commentId, threadId: input.threadId,
        data: input.data ?? {}, expiresAt: input.expiresAt,
      } });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return this.prisma.notification.findUniqueOrThrow({
          where: { userId_dedupeKey: { userId: input.userId, dedupeKey: input.dedupeKey } },
        });
      }
      throw error;
    }
    const preference = await this.preferences(input.userId);
    const setting: Partial<Record<NotificationType, keyof typeof preference>> = {
      CHAPTER_UPDATE: 'libraryUpdates', COMMENT_REPLY: 'commentReplies',
      COMMENT_MENTION: 'commentMentions', COMMENT_LIKE: 'commentLikes',
      COMMENT_MODERATION: 'moderation', SOURCE_OUTAGE: 'sourceStatus',
      SOURCE_RESTORED: 'sourceStatus', SYSTEM_ANNOUNCEMENT: 'productAnnouncements',
    };
    const key = setting[input.type];
    const enabled = input.push !== false && (!key || preference[key] === true);
    await this.push.deliver(notification, enabled);
    return notification;
  }

  async recordLike(comment: { id: string; userId: string; sourceId: string;
    mangaId: string; chapterId: string; parentId: string | null },
    actorId: string, actorName: string) {
    const dedupeKey = `likes:${comment.id}`;
    const existing = await this.prisma.notification.findUnique({
      where: { userId_dedupeKey: { userId: comment.userId, dedupeKey } },
    });
    if (existing) {
      const data = (existing.data || {}) as { actors?: string[]; firstActor?: string };
      const actors = [...new Set([...(data.actors || []), actorId])];
      if (actors.length === (data.actors || []).length) return existing;
      return this.prisma.notification.update({ where: { id: existing.id }, data: {
        title: `${data.firstActor || actorName} and ${actors.length - 1} others liked your comment`,
        data: { actors, firstActor: data.firstActor || actorName }, readAt: null,
      } });
    }
    return this.create({ userId: comment.userId, type: NotificationType.COMMENT_LIKE,
      title: `${actorName} liked your comment`, body: 'Open your comment to see the conversation.',
      actorUserId: actorId, sourceId: comment.sourceId, mangaId: comment.mangaId,
      chapterId: comment.chapterId, commentId: comment.id,
      threadId: comment.parentId || comment.id,
      deepLink: notificationLinks.comment(comment.sourceId, comment.mangaId, comment.chapterId, comment.id),
      groupingKey: `likes:${comment.id}`, dedupeKey,
      data: { actors: [actorId], firstActor: actorName } });
  }

  async registerDevice(userId: string, installationId: string, platform: PushPlatform,
    token: string, appVersion: string) {
    if (!installationId || !token || !appVersion ||
      (platform === 'IOS' && !/^[a-fA-F0-9]{64}$/.test(token)))
      throw new BadRequestException('Invalid device registration');
    // A token and an installation must each have one owner, even after account switching.
    const device = await this.prisma.$transaction(async (tx) => {
      await tx.pushDevice.deleteMany({ where: { OR: [{ installationId }, { token }] } });
      return tx.pushDevice.create({ data: { userId, installationId, platform, token, appVersion,
        lastSeenAt: new Date(), enabled: true } });
    });
    const minimum = process.env[platform === 'IOS' ? 'MIN_IOS_APP_VERSION' : 'MIN_ANDROID_APP_VERSION'];
    if (minimum && compareVersions(appVersion, minimum) < 0) {
      await this.create({ userId, type: NotificationType.APP_UPDATE_REQUIRED,
        title: 'Keihatsu update required', body: 'Update Keihatsu to keep using your account.',
        deepLink: notificationLinks.update(), dedupeKey: `required-update:${platform}:${minimum}`,
        groupingKey: 'required-update', data: { minimumVersion: minimum } });
    }
    return { id: device.id, installationId: device.installationId, platform: device.platform,
      appVersion: device.appVersion, enabled: device.enabled };
  }

  async unregisterDevice(userId: string, installationId: string) {
    await this.prisma.pushDevice.deleteMany({ where: { userId, installationId } });
    return { success: true };
  }

  async list(userId: string, query: { cursor?: string; limit?: string; type?: string;
    category?: string; unread?: string }) {
    const limit = Math.min(Math.max(Number(query.limit) || 30, 1), 100);
    const types = query.type ? [query.type] : query.category ? notificationCategories[query.category.toUpperCase()] : undefined;
    if ((query.type && !Object.values(NotificationType).includes(query.type as NotificationType)) ||
      (query.category && !types)) throw new BadRequestException('Invalid notification filter');
    if (query.unread && !['true', 'false'].includes(query.unread)) throw new BadRequestException('Invalid unread filter');
    const where: Prisma.NotificationWhereInput = { userId,
      OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
      ...(types && { type: { in: types as NotificationType[] } }),
      ...(query.unread && { readAt: query.unread === 'true' ? null : { not: null } }),
    };
    if (query.cursor) {
      const cursor = await this.prisma.notification.findFirst({ where: { id: query.cursor, userId } });
      if (!cursor) throw new BadRequestException('Invalid cursor');
      where.AND = [{ OR: [{ createdAt: { lt: cursor.createdAt } },
        { createdAt: cursor.createdAt, id: { lt: cursor.id } }] }];
    }
    const rows = await this.prisma.notification.findMany({ where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1 });
    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit);
    return { items, nextCursor: hasMore ? items[items.length - 1].id : null };
  }

  async unreadCount(userId: string) {
    return { count: await this.prisma.notification.count({ where: { userId, readAt: null,
      OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }] } }) };
  }

  async markRead(userId: string, id: string) {
    const result = await this.prisma.notification.updateMany({
      where: { id, userId, readAt: null }, data: { readAt: new Date() },
    });
    if (!result.count && !(await this.prisma.notification.findFirst({ where: { id, userId } })))
      throw new NotFoundException('Notification not found');
    return this.prisma.notification.findFirst({ where: { id, userId } });
  }

  async readAll(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { userId, readAt: null }, data: { readAt: new Date() },
    });
    return { count: result.count };
  }

  async remove(userId: string, id: string) {
    const result = await this.prisma.notification.deleteMany({ where: { id, userId } });
    if (!result.count) throw new NotFoundException('Notification not found');
    return { success: true };
  }

  async preferences(userId: string) {
    return this.prisma.notificationPreference.upsert({ where: { userId },
      create: { userId }, update: {} });
  }

  async updatePreferences(userId: string, values: Record<string, boolean>) {
    const allowed = ['libraryUpdates', 'commentReplies', 'commentMentions', 'commentLikes',
      'moderation', 'sourceStatus', 'productAnnouncements'];
    if (Object.keys(values).some((key) => !allowed.includes(key) || typeof values[key] !== 'boolean'))
      throw new BadRequestException('Invalid preference');
    return this.prisma.notificationPreference.upsert({ where: { userId },
      create: { userId, ...values }, update: values });
  }
}

function compareVersions(a: string, b: string) {
  const left = a.split('.').map(Number), right = b.split('.').map(Number);
  for (let i = 0; i < Math.max(left.length, right.length); i++) {
    const difference = (left[i] || 0) - (right[i] || 0);
    if (difference) return difference;
  }
  return 0;
}
