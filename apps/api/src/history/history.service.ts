import { ConflictException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SyncHistoryDto } from './dto/sync-history.dto';

@Injectable()
export class HistoryService {
  constructor(private prisma: PrismaService) {}

  async syncHistory(userId: string, data: SyncHistoryDto) {
    const lastReadAt = data.lastReadAt ? new Date(data.lastReadAt) : new Date();

    return this.prisma.$transaction(async (tx) => {
      const identity = {
        userId,
        sourceId: data.sourceId,
        mangaId: data.mangaId,
        chapterId: data.chapterId,
      };
      const processed = await tx.historySyncEvent.findUnique({
        where: {
          userId_operationId: { userId, operationId: data.operationId },
        },
      });
      if (processed) {
        const priorResult = await tx.historyEntry.findUnique({
          where: { userId_sourceId_mangaId_chapterId: identity },
        });
        if (!priorResult) {
          throw new ConflictException('Operation identity does not match');
        }
        return priorResult;
      }

      await tx.historySyncEvent.create({
        data: { userId, operationId: data.operationId },
      });
      const existing = await tx.historyEntry.findUnique({
        where: { userId_sourceId_mangaId_chapterId: identity },
      });
      const snapshot = this.historySnapshot(data);
      const historyEntry = existing
        ? lastReadAt >= existing.lastReadAt
          ? await tx.historyEntry.update({
              where: { id: existing.id },
              data: {
                pageNumber: data.pageNumber ?? existing.pageNumber,
                lastReadAt,
                isBookmarked: data.isBookmarked ?? existing.isBookmarked,
                isRead: data.isRead ?? existing.isRead,
                deletedAt: null,
                ...snapshot,
              },
            })
          : existing
        : await tx.historyEntry.create({
            data: {
              ...identity,
              pageNumber: data.pageNumber ?? 0,
              lastReadAt,
              isBookmarked: data.isBookmarked ?? false,
              isRead: data.isRead ?? false,
              ...snapshot,
            },
          });

      const libraryEntry = await tx.libraryEntry.findUnique({
        where: {
          userId_sourceId_mangaId: {
            userId,
            sourceId: data.sourceId,
            mangaId: data.mangaId,
          },
        },
      });
      if (
        libraryEntry &&
        lastReadAt >= (libraryEntry.lastReadAt ?? new Date(0))
      ) {
        await tx.libraryEntry.update({
          where: { id: libraryEntry.id },
          data: {
            lastReadAt,
            ...this.buildLibrarySnapshotUpdate(data),
          },
        });
      }

      if (data.readingTimeMs && data.readingTimeMs > 0) {
        await this.addReadingTime(tx, userId, lastReadAt, data.readingTimeMs);
      }
      return historyEntry;
    });
  }

  async getHistory(
    userId: string,
    page = 1,
    limit = 50,
    includeDeleted = false,
  ) {
    const entries = await this.prisma.historyEntry.findMany({
      where: { userId, ...(includeDeleted ? {} : { deletedAt: null }) },
      orderBy: { lastReadAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });
    const identities = entries.map(({ sourceId, mangaId }) => ({
      sourceId,
      mangaId,
    }));
    const libraryEntries = identities.length
      ? await this.prisma.libraryEntry.findMany({
          where: { userId, OR: identities },
          select: {
            sourceId: true,
            mangaId: true,
            title: true,
            thumbnailUrl: true,
            author: true,
            totalChapters: true,
          },
        })
      : [];
    const library = new Map(
      libraryEntries.map((entry) => [
        `${entry.sourceId}\u0000${entry.mangaId}`,
        entry,
      ]),
    );

    return entries.map((entry) => {
      const fallback = library.get(`${entry.sourceId}\u0000${entry.mangaId}`);
      return {
        ...entry,
        title: entry.title ?? fallback?.title ?? null,
        thumbnailUrl: entry.thumbnailUrl ?? fallback?.thumbnailUrl ?? null,
        author: entry.author ?? fallback?.author ?? null,
        totalChapters: fallback?.totalChapters ?? null,
        displayDate: this.formatHistoryDisplayDate(entry.lastReadAt),
      };
    });
  }

  async deleteHistoryEntry(
    userId: string,
    mangaId: string,
    sourceId?: string,
    operationId?: string,
    deletedAtValue?: string,
  ) {
    const deletedAt = deletedAtValue ? new Date(deletedAtValue) : new Date();
    return this.prisma.$transaction(async (tx) => {
      if (operationId) {
        const processed = await tx.historySyncEvent.findUnique({
          where: { userId_operationId: { userId, operationId } },
        });
        if (processed) return { count: 0 };
        await tx.historySyncEvent.create({ data: { userId, operationId } });
      }
      return tx.historyEntry.updateMany({
        where: {
          userId,
          mangaId,
          ...(sourceId ? { sourceId } : {}),
          OR: [{ deletedAt: null }, { deletedAt: { lt: deletedAt } }],
        },
        data: { deletedAt },
      });
    });
  }

  private historySnapshot(data: SyncHistoryDto) {
    return {
      title: data.title?.trim() || undefined,
      thumbnailUrl: data.thumbnailUrl?.trim() || undefined,
      author: data.author?.trim() || undefined,
      chapterName: data.chapterName?.trim() || undefined,
      chapterNumber: data.chapterNumber,
    };
  }

  private buildLibrarySnapshotUpdate(data: SyncHistoryDto) {
    return {
      title: data.title?.trim() || undefined,
      thumbnailUrl: data.thumbnailUrl?.trim() || undefined,
      author: data.author?.trim() || undefined,
    };
  }

  private async addReadingTime(
    tx: Prisma.TransactionClient,
    userId: string,
    lastReadAt: Date,
    readingTimeMs: number,
  ) {
    const dateKey = lastReadAt.toISOString().split('T')[0];
    const user = await tx.user.findUnique({
      where: { id: userId },
      select: { readingStats: true },
    });
    const currentStats = (user?.readingStats as Record<string, number>) || {};
    await tx.user.update({
      where: { id: userId },
      data: {
        readingStats: {
          ...currentStats,
          [dateKey]: (currentStats[dateKey] || 0) + readingTimeMs,
        },
      },
    });
  }

  private formatHistoryDisplayDate(date: Date) {
    const day = date.getUTCDate();
    const month = new Intl.DateTimeFormat('en-GB', {
      month: 'long',
      timeZone: 'UTC',
    }).format(date);
    return `${day}${this.getOrdinalSuffix(day)} ${month} ${date.getUTCFullYear()}`;
  }

  private getOrdinalSuffix(day: number) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
