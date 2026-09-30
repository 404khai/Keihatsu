import { BadRequestException, Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PushPlatform, NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { notificationLinks } from './notification-links';

export type AnnouncementInput = {
  title: string; body: string; platform?: PushPlatform; minAppVersion?: string;
  maxAppVersion?: string; deepLink?: string; severity: 'INFO' | 'IMPORTANT' | 'CRITICAL';
  pushEnabled: boolean; publishAt: string; expiresAt?: string;
};

@Injectable()
export class AnnouncementService implements OnModuleInit, OnModuleDestroy {
  private timer?: NodeJS.Timeout;
  constructor(private prisma: PrismaService, private notifications: NotificationsService) {}
  onModuleInit() { this.timer = setInterval(() => void this.publishDue(), 60000); void this.publishDue(); }
  onModuleDestroy() { if (this.timer) clearInterval(this.timer); }

  async create(input: AnnouncementInput) {
    if (!input.title?.trim() || !input.body?.trim() || input.title.length > 160 || input.body.length > 500 ||
      !['INFO', 'IMPORTANT', 'CRITICAL'].includes(input.severity) ||
      (input.platform && !Object.values(PushPlatform).includes(input.platform)) ||
      typeof input.pushEnabled !== 'boolean' ||
      !Number.isFinite(Date.parse(input.publishAt)) ||
      (input.expiresAt && (!Number.isFinite(Date.parse(input.expiresAt)) ||
        Date.parse(input.expiresAt) <= Date.parse(input.publishAt))) ||
      (input.deepLink && !/^keihatsu:\/\/(inbox|manga|chapter|comment|announcement|settings)(\/|$)/.test(input.deepLink)))
      throw new BadRequestException('Invalid announcement');
    const row = await this.prisma.systemAnnouncement.create({ data: {
      ...input, publishAt: new Date(input.publishAt),
      expiresAt: input.expiresAt ? new Date(input.expiresAt) : undefined,
    } });
    if (row.publishAt <= new Date()) await this.publishDue();
    return row;
  }

  async publishDue() {
    const due = await this.prisma.systemAnnouncement.findMany({
      where: { publishedAt: null, publishAt: { lte: new Date() },
        OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }] }, take: 20,
    });
    for (const item of due) {
      const devices = await this.prisma.pushDevice.findMany({ where: {
        enabled: true, ...(item.platform && { platform: item.platform }),
      }, select: { userId: true, appVersion: true } });
      const users = new Set(devices.filter((device) =>
        (!item.minAppVersion || compareVersions(device.appVersion, item.minAppVersion) >= 0) &&
        (!item.maxAppVersion || compareVersions(device.appVersion, item.maxAppVersion) <= 0))
        .map((device) => device.userId));
      if (!item.platform && !item.minAppVersion && !item.maxAppVersion) {
        const all = await this.prisma.user.findMany({ select: { id: true } });
        for (const user of all) users.add(user.id);
      }
      for (const userId of users) {
        await this.notifications.create({ userId, type: NotificationType.SYSTEM_ANNOUNCEMENT,
          title: item.title, body: item.body, deepLink: item.deepLink || notificationLinks.announcement(item.id),
          dedupeKey: `announcement:${item.id}`, groupingKey: `announcement:${item.id}`,
          data: { severity: item.severity }, push: item.pushEnabled, expiresAt: item.expiresAt || undefined });
      }
      await this.prisma.systemAnnouncement.update({ where: { id: item.id }, data: { publishedAt: new Date() } });
    }
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
