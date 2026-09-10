import { Test, TestingModule } from '@nestjs/testing';
import { HistoryService } from './history.service';
import { PrismaService } from '../prisma/prisma.service';

describe('HistoryService', () => {
  let service: HistoryService;
  const prismaService = {
    historyEntry: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
    },
    historySyncEvent: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    libraryEntry: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    $transaction: jest.fn(async (callback) => callback(prismaService)),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HistoryService,
        {
          provide: PrismaService,
          useValue: prismaService,
        },
      ],
    }).compile();

    service = module.get<HistoryService>(HistoryService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('adds a display-ready date to history results', async () => {
    prismaService.historyEntry.findMany.mockResolvedValue([
      {
        id: 'history-1',
        userId: 'user-1',
        mangaId: 'manga-1',
        sourceId: 'weebcentral',
        chapterId: 'chapter-1',
        pageNumber: 12,
        lastReadAt: new Date('2026-04-24T00:00:00.000Z'),
        isBookmarked: false,
        isRead: true,
        title: null,
        thumbnailUrl: null,
        author: null,
      },
    ]);
    prismaService.libraryEntry.findMany.mockResolvedValue([
      {
        sourceId: 'weebcentral',
        mangaId: 'manga-1',
        title: 'Solo Leveling',
        thumbnailUrl: 'https://cdn.example.com/cover.jpg',
        author: 'Chugong',
        totalChapters: 200,
      },
    ]);

    const result = await service.getHistory('user-1');

    expect(result).toEqual([
      expect.objectContaining({
        displayDate: '24th April 2026',
        title: 'Solo Leveling',
        thumbnailUrl: 'https://cdn.example.com/cover.jpg',
      }),
    ]);
  });

  it('refreshes library snapshot data during history sync', async () => {
    const lastReadAt = '2026-04-24T00:00:00.000Z';
    prismaService.historySyncEvent.findUnique.mockResolvedValue(null);
    prismaService.historySyncEvent.create.mockResolvedValue({ id: 'event-1' });
    prismaService.historyEntry.findUnique.mockResolvedValue(null);
    prismaService.historyEntry.create.mockResolvedValue({ id: 'history-1' });
    prismaService.libraryEntry.findUnique.mockResolvedValue({
      id: 'library-1',
      lastReadAt: null,
    });
    prismaService.libraryEntry.update.mockResolvedValue({ id: 'library-1' });

    await service.syncHistory('user-1', {
      operationId: '428d294c-113f-4eca-8cd2-30aa8e60b314',
      mangaId: 'manga-1',
      sourceId: 'weebcentral',
      chapterId: 'chapter-1',
      lastReadAt,
      title: ' Solo Leveling ',
      thumbnailUrl: 'https://cdn.example.com/cover.jpg',
      author: ' Chugong ',
    });

    expect(prismaService.libraryEntry.update).toHaveBeenCalledWith({
      where: { id: 'library-1' },
      data: {
        lastReadAt: new Date(lastReadAt),
        title: 'Solo Leveling',
        thumbnailUrl: 'https://cdn.example.com/cover.jpg',
        author: 'Chugong',
      },
    });
  });

  it('acknowledges a repeated operation without adding reading time twice', async () => {
    const existing = {
      id: 'history-1',
      lastReadAt: new Date('2026-04-24T00:00:00.000Z'),
    };
    prismaService.historySyncEvent.findUnique.mockResolvedValue({
      id: 'event-1',
    });
    prismaService.historyEntry.findUnique.mockResolvedValue(existing);

    const result = await service.syncHistory('user-1', {
      operationId: '428d294c-113f-4eca-8cd2-30aa8e60b314',
      mangaId: 'manga-1',
      sourceId: 'weebcentral',
      chapterId: 'chapter-1',
      readingTimeMs: 5000,
    });

    expect(result).toEqual(existing);
    expect(prismaService.user.update).not.toHaveBeenCalled();
    expect(prismaService.historySyncEvent.create).not.toHaveBeenCalled();
  });
});
