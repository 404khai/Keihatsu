import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncHistoryDto } from './dto/sync-history.dto';

@Injectable()
export class HistoryService {
  constructor(private prisma: PrismaService) {}

  async syncHistory(userId: string, data: SyncHistoryDto) {
    const lastReadAt = data.lastReadAt ? new Date(data.lastReadAt) : new Date();

    const historyEntry = await this.prisma.historyEntry.upsert({
      where: {
        userId_mangaId_chapterId: {
          userId,
          mangaId: data.mangaId,
          chapterId: data.chapterId,
        },
      },
      update: {
        pageNumber: data.pageNumber,
        lastReadAt: lastReadAt,
        sourceId: data.sourceId,
        isBookmarked: data.isBookmarked,
        isRead: data.isRead,
      },
      create: {
        userId,
        mangaId: data.mangaId,
        sourceId: data.sourceId,
        chapterId: data.chapterId,
        pageNumber: data.pageNumber || 0,
        lastReadAt: lastReadAt,
        isBookmarked: data.isBookmarked || false,
        isRead: data.isRead || false,
      },
    });

    // Update Library Entry (for sorting)
    const libraryEntry = await this.prisma.libraryEntry.findUnique({
      where: {
        userId_mangaId: {
          userId,
          mangaId: data.mangaId,
        },
      },
    });

    if (libraryEntry) {
      await this.prisma.libraryEntry.update({
        where: { id: libraryEntry.id },
        data: {
          lastReadAt: lastReadAt,
          ...this.buildLibrarySnapshotUpdate(data),
        },
      });
    }

    // Update Reading Stats
    if (data.readingTimeMs && data.readingTimeMs > 0) {
      const dateKey = lastReadAt.toISOString().split('T')[0];
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { readingStats: true },
      });

      const currentStats = (user?.readingStats as Record<string, number>) || {};
      const currentDuration = currentStats[dateKey] || 0;

      await this.prisma.user.update({
        where: { id: userId },
        data: {
          readingStats: {
            ...currentStats,
            [dateKey]: currentDuration + data.readingTimeMs,
          },
        },
      });
    }

    return historyEntry;
  }

  async getHistory(userId: string, page = 1, limit = 50) {
    const entries = await this.prisma.historyEntry.findMany({
      where: { userId },
      orderBy: { lastReadAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    });

    const mangaIds = [...new Set(entries.map((entry) => entry.mangaId))];
    const libraryEntries =
      mangaIds.length > 0
        ? await this.prisma.libraryEntry.findMany({
            where: {
              userId,
              mangaId: { in: mangaIds },
            },
            select: {
              mangaId: true,
              title: true,
              thumbnailUrl: true,
              author: true,
              totalChapters: true,
            },
          })
        : [];

    const libraryByMangaId = new Map(
      libraryEntries.map((entry) => [entry.mangaId, entry]),
    );

    return entries.map((entry) => {
      const libraryEntry = libraryByMangaId.get(entry.mangaId);

      return {
        ...entry,
        title: libraryEntry?.title ?? null,
        thumbnailUrl: libraryEntry?.thumbnailUrl ?? null,
        author: libraryEntry?.author ?? null,
        totalChapters: libraryEntry?.totalChapters ?? null,
        displayDate: this.formatHistoryDisplayDate(entry.lastReadAt),
        chapterName: null,
        chapterNumber: null,
      };
    });
  }

  private buildLibrarySnapshotUpdate(data: SyncHistoryDto) {
    const updateData: {
      sourceId?: string;
      title?: string;
      thumbnailUrl?: string;
      author?: string;
    } = {
      sourceId: data.sourceId,
    };

    if (data.title?.trim()) {
      updateData.title = data.title.trim();
    }

    if (data.thumbnailUrl?.trim()) {
      updateData.thumbnailUrl = data.thumbnailUrl.trim();
    }

    if (data.author?.trim()) {
      updateData.author = data.author.trim();
    }

    return updateData;
  }

  private formatHistoryDisplayDate(date: Date) {
    const day = date.getUTCDate();
    const month = new Intl.DateTimeFormat('en-GB', {
      month: 'long',
      timeZone: 'UTC',
    }).format(date);
    const year = date.getUTCFullYear();

    return `${day}${this.getOrdinalSuffix(day)} ${month} ${year}`;
  }

  private getOrdinalSuffix(day: number) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }

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

  async deleteHistoryEntry(userId: string, mangaId: string) {
    return this.prisma.historyEntry.deleteMany({
      where: {
        userId,
        mangaId,
      },
    });
  }
}
