import { Test, TestingModule } from '@nestjs/testing';
import { LibraryService } from './library.service';
import { PrismaService } from '../prisma/prisma.service';

describe('LibraryService', () => {
  let service: LibraryService;
  const prismaService = {
    libraryEntry: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    category: {
      findMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LibraryService,
        {
          provide: PrismaService,
          useValue: prismaService,
        },
      ],
    }).compile();

    service = module.get<LibraryService>(LibraryService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('refreshes stored metadata when the entry already exists', async () => {
    const existingEntry = {
      id: 'library-1',
      userId: 'user-1',
      mangaId: 'manga-1',
    };
    const updatedEntry = {
      ...existingEntry,
      title: 'Solo Leveling',
      thumbnailUrl: 'https://cdn.example.com/cover.jpg',
      author: 'Chugong',
      language: 'EN',
    };

    prismaService.libraryEntry.findUnique.mockResolvedValue(existingEntry);
    prismaService.libraryEntry.update.mockResolvedValue(updatedEntry);

    const result = await service.create('user-1', {
      mangaId: 'manga-1',
      sourceId: 'weebcentral',
      title: ' Solo Leveling ',
      thumbnailUrl: 'https://cdn.example.com/cover.jpg',
      author: ' Chugong ',
      language: ' EN ',
    });

    expect(prismaService.libraryEntry.update).toHaveBeenCalledWith({
      where: { id: 'library-1' },
      data: {
        sourceId: 'weebcentral',
        title: 'Solo Leveling',
        thumbnailUrl: 'https://cdn.example.com/cover.jpg',
        author: 'Chugong',
        language: 'EN',
      },
    });
    expect(result).toEqual(updatedEntry);
  });

  it('replaces a library entry category set after ownership validation', async () => {
    prismaService.libraryEntry.findUnique.mockResolvedValue({
      id: 'library-1',
      userId: 'user-1',
    });
    prismaService.category.findMany.mockResolvedValue([
      { id: 'category-1' },
      { id: 'category-2' },
    ]);
    prismaService.libraryEntry.update.mockResolvedValue({ id: 'library-1' });

    await service.setCategories('library-1', 'user-1', [
      'category-1',
      'category-2',
    ]);

    expect(prismaService.libraryEntry.update).toHaveBeenCalledWith({
      where: { id: 'library-1' },
      data: {
        categories: {
          set: [{ id: 'category-1' }, { id: 'category-2' }],
        },
      },
      include: { categories: true },
    });
  });
});
