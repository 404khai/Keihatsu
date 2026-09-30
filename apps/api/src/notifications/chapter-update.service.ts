import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SourcesService } from '../sources/sources.service';
import { NotificationsService } from './notifications.service';
import { notificationLinks } from './notification-links';

@Injectable()
export class ChapterUpdateService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ChapterUpdateService.name);
  private timer?: NodeJS.Timeout;
  private running = false;
  constructor(private prisma: PrismaService, private sources: SourcesService,
    private notifications: NotificationsService) {}

  onModuleInit() {
    const interval = Number(process.env.CHAPTER_CHECK_INTERVAL_MS || 0);
    if (interval >= 60000) this.timer = setInterval(() => void this.checkAll(), interval);
  }
  onModuleDestroy() { if (this.timer) clearInterval(this.timer); }

  async checkAll() {
    if (this.running) return;
    this.running = true;
    try {
      const unique = await this.prisma.libraryEntry.findMany({
        distinct: ['sourceId', 'mangaId'], select: { sourceId: true, mangaId: true },
      });
      const concurrency = Math.max(1, Math.min(Number(process.env.CHAPTER_CHECK_CONCURRENCY || 2), 8));
      const bySource = new Map<string, string[]>();
      for (const entry of unique) bySource.set(entry.sourceId, [...(bySource.get(entry.sourceId) || []), entry.mangaId]);
      for (const [sourceId, mangaIds] of bySource) {
        let succeeded = 0;
        for (let i = 0; i < mangaIds.length; i += concurrency) {
          await Promise.all(mangaIds.slice(i, i + concurrency).map(async (mangaId) => {
            try { await this.checkManga(sourceId, mangaId); succeeded++; }
            catch { this.logger.warn(`Chapter check failed source=${sourceId} manga=${mangaId}`); }
          }));
        }
        await this.recordSourceResult(sourceId, succeeded > 0);
      }
    } finally { this.running = false; }
  }

  async checkManga(sourceId: string, mangaId: string) {
    const chapters = await this.sources.getChapterList(sourceId, mangaId);
    // An empty scrape is often a temporary failure; retain the last known snapshot.
    if (!chapters.length) throw new Error('Empty chapter list');
    const previous = await this.prisma.chapterSnapshot.findUnique({
      where: { sourceId_mangaId: { sourceId, mangaId } },
    });
    const chapterIds = [...new Set(chapters.map((chapter) => chapter.id))];
    const previousIds = new Set((previous?.chapterIds || []) as string[]);
    const added = previous ? chapters.filter((chapter) => !previousIds.has(chapter.id)) : [];
    if (!added.length) {
      await this.saveSnapshot(sourceId, mangaId, chapterIds);
      return { added: 0, notified: 0 };
    }
    const subscribers = await this.prisma.libraryEntry.findMany({
      where: { sourceId, mangaId }, select: { userId: true, title: true, dateAddedAt: true },
    });
    let notified = 0;
    for (const subscriber of subscribers) {
      const eligible = added.filter((chapter) => chapter.dateUpload > 0
        ? chapter.dateUpload >= subscriber.dateAddedAt.getTime()
        : !!previous && subscriber.dateAddedAt <= previous.lastSuccessAt);
      if (!eligible.length) continue;
      const ids = eligible.map((chapter) => chapter.id).sort();
      await this.notifications.create({ userId: subscriber.userId, type: NotificationType.CHAPTER_UPDATE,
        title: `${eligible.length} new ${eligible.length === 1 ? 'chapter' : 'chapters'} of ${subscriber.title}`,
        body: eligible.length === 1 ? eligible[0].name : 'New chapters are ready to read.',
        sourceId, mangaId, chapterId: eligible.length === 1 ? eligible[0].id : undefined,
        deepLink: eligible.length === 1
          ? notificationLinks.chapter(sourceId, mangaId, eligible[0].id)
          : notificationLinks.manga(sourceId, mangaId),
        groupingKey: `chapters:${sourceId}:${mangaId}`,
        dedupeKey: `chapters:${sourceId}:${mangaId}:${ids.join('|')}`,
        data: { chapterIds: ids },
      });
      notified++;
    }
    await this.saveSnapshot(sourceId, mangaId, chapterIds);
    return { added: added.length, notified };
  }

  private async saveSnapshot(sourceId: string, mangaId: string, chapterIds: string[]) {
    await this.prisma.chapterSnapshot.upsert({
      where: { sourceId_mangaId: { sourceId, mangaId } },
      create: { sourceId, mangaId, chapterIds },
      update: { chapterIds, lastSuccessAt: new Date() },
    });
  }

  private async recordSourceResult(sourceId: string, succeeded: boolean) {
    const prior = await this.prisma.sourceHealth.findUnique({ where: { sourceId } });
    const now = new Date();
    if (succeeded) {
      await this.prisma.sourceHealth.upsert({ where: { sourceId },
        create: { sourceId, lastSuccessAt: now },
        update: { failureCount: 0, lastSuccessAt: now, outageAnnouncedAt: null } });
      if (prior?.outageAnnouncedAt) {
        await this.notifySourceUsers(sourceId, NotificationType.SOURCE_RESTORED,
          'Source is available again', 'Your library source is responding again.',
          `restored:${sourceId}:${prior.outageAnnouncedAt.toISOString()}`, false);
      }
      return;
    }
    const failures = (prior?.failureCount || 0) + 1;
    const important = failures >= Math.max(2, Number(process.env.SOURCE_OUTAGE_THRESHOLD || 3));
    await this.prisma.sourceHealth.upsert({ where: { sourceId },
      create: { sourceId, failureCount: failures, lastFailureAt: now,
        outageAnnouncedAt: important ? now : null },
      update: { failureCount: failures, lastFailureAt: now,
        ...(important && !prior?.outageAnnouncedAt ? { outageAnnouncedAt: now } : {}) } });
    if (important && !prior?.outageAnnouncedAt) {
      await this.notifySourceUsers(sourceId, NotificationType.SOURCE_OUTAGE,
        'Library source unavailable', 'A source in your library has been unavailable across multiple checks.',
        `outage:${sourceId}:${now.toISOString()}`, true);
    }
  }

  private async notifySourceUsers(sourceId: string, type: NotificationType,
    title: string, body: string, dedupeKey: string, push: boolean) {
    const entries = await this.prisma.libraryEntry.findMany({ where: { sourceId },
      distinct: ['userId'], select: { userId: true } });
    for (const entry of entries) await this.notifications.create({ userId: entry.userId,
      type, title, body, sourceId, deepLink: notificationLinks.inbox(),
      groupingKey: `source:${sourceId}`, dedupeKey, push });
  }
}
