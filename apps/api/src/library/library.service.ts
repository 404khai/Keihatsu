import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateLibraryEntryDto,
  UpdateLibraryEntryDto,
} from './dto/library-entry.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class LibraryService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createDto: CreateLibraryEntryDto) {
    // Check if already exists
    const existing = await this.prisma.libraryEntry.findUnique({
      where: {
        userId_sourceId_mangaId: {
          userId,
          sourceId: createDto.sourceId,
          mangaId: createDto.mangaId,
        },
      },
    });

    if (existing) {
      const metadataUpdate = this.buildMetadataUpdate(createDto);

      if (Object.keys(metadataUpdate).length === 0) {
        // Return existing entry — the client needs the `id` (serverId) to sync
        return existing;
      }

      return this.prisma.libraryEntry.update({
        where: { id: existing.id },
        data: metadataUpdate,
      });
    }

    return this.prisma.libraryEntry.create({
      data: {
        ...createDto,
        userId,
        isBookmarked: true, // Default to bookmarked when adding
      },
    });
  }

  async findAll(userId: string, query: any) {
    const {
      filter_downloaded,
      filter_unread,
      filter_started,
      filter_bookmarked,
      filter_completed,
      sort_by,
      order = 'asc',
      search,
    } = query;

    const where: Prisma.LibraryEntryWhereInput = {
      userId,
    };

    // Filtering
    if (filter_downloaded === 'true') {
      where.downloadedCount = { gt: 0 };
    }
    if (filter_unread === 'true') {
      where.isUnread = true;
    }
    if (filter_started === 'true') {
      where.isStarted = true;
    }
    if (filter_bookmarked === 'true') {
      where.isBookmarked = true;
    }
    if (filter_completed === 'true') {
      where.isCompleted = true;
    }

    // Search
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { author: { contains: search, mode: 'insensitive' } },
      ];
    }

    // Sorting
    const orderBy: Prisma.LibraryEntryOrderByWithRelationInput = {};
    const sortOrder = order === 'desc' ? 'desc' : 'asc';

    switch (sort_by) {
      case 'alphabetical':
        orderBy.title = sortOrder;
        break;
      case 'last_read':
        orderBy.lastReadAt = sortOrder;
        break;
      case 'last_updated':
        orderBy.lastUpdatedAt = sortOrder;
        break;
      case 'unread_count':
        orderBy.unreadCount = sortOrder;
        break;
      case 'total_chapters':
        orderBy.totalChapters = sortOrder;
        break;
      case 'date_added':
      default:
        orderBy.dateAddedAt = sortOrder;
        break;
    }

    return this.prisma.libraryEntry.findMany({
      where,
      orderBy,
      include: {
        categories: true,
      },
    });
  }

  async update(id: string, userId: string, updateDto: UpdateLibraryEntryDto) {
    const entry = await this.prisma.libraryEntry.findUnique({
      where: { id },
    });

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Library entry not found');
    }

    return this.prisma.libraryEntry.update({
      where: { id },
      data: updateDto,
    });
  }

  async remove(id: string, userId: string) {
    const entry = await this.prisma.libraryEntry.findUnique({
      where: { id },
    });

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Library entry not found');
    }

    return this.prisma.libraryEntry.delete({
      where: { id },
    });
  }

  async setCategories(id: string, userId: string, categoryIds: string[]) {
    const [entry, ownedCategories] = await Promise.all([
      this.prisma.libraryEntry.findUnique({ where: { id } }),
      this.prisma.category.findMany({
        where: { userId, id: { in: categoryIds } },
        select: { id: true },
      }),
    ]);

    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Library entry not found');
    }
    if (ownedCategories.length !== categoryIds.length) {
      throw new NotFoundException('One or more categories were not found');
    }

    return this.prisma.libraryEntry.update({
      where: { id },
      data: { categories: { set: ownedCategories } },
      include: { categories: true },
    });
  }

  private buildMetadataUpdate(createDto: CreateLibraryEntryDto) {
    const metadataUpdate: {
      sourceId?: string;
      title?: string;
      thumbnailUrl?: string;
      author?: string;
      language?: string;
    } = {};

    if (createDto.sourceId) {
      metadataUpdate.sourceId = createDto.sourceId;
    }

    if (createDto.title?.trim()) {
      metadataUpdate.title = createDto.title.trim();
    }

    if (createDto.thumbnailUrl?.trim()) {
      metadataUpdate.thumbnailUrl = createDto.thumbnailUrl.trim();
    }

    if (createDto.author?.trim()) {
      metadataUpdate.author = createDto.author.trim();
    }

    if (createDto.language?.trim()) {
      metadataUpdate.language = createDto.language.trim();
    }

    return metadataUpdate;
  }
}
