import { ChapterUpdateService } from './chapter-update.service';

describe('ChapterUpdateService', () => {
  const prisma = {
    chapterSnapshot: { findUnique: jest.fn(), upsert: jest.fn() },
    libraryEntry: { findMany: jest.fn() },
  };
  const sources = { getChapterList: jest.fn() };
  const notifications = { preferences: jest.fn(), create: jest.fn() };
  const service = new ChapterUpdateService(prisma as any, sources as any, notifications as any);
  const chapter = (id: string, dateUpload: number) => ({ id, dateUpload, name: `Chapter ${id}` });
  beforeEach(() => jest.clearAllMocks());

  it('silently establishes the first successful snapshot', async () => {
    sources.getChapterList.mockResolvedValue([chapter('old', Date.now() - 100000)]);
    prisma.chapterSnapshot.findUnique.mockResolvedValue(null);
    expect(await service.checkManga('source', 'manga')).toEqual({ added: 0, notified: 0 });
    expect(prisma.chapterSnapshot.upsert).toHaveBeenCalledTimes(1);
    expect(notifications.create).not.toHaveBeenCalled();
  });

  it('groups new chapters and excludes chapters older than library addition', async () => {
    const now = Date.now();
    sources.getChapterList.mockResolvedValue([chapter('old', now - 100000), chapter('new-1', now), chapter('new-2', now)]);
    prisma.chapterSnapshot.findUnique.mockResolvedValue({ chapterIds: ['old'] });
    prisma.libraryEntry.findMany.mockResolvedValue([
      { userId: 'eligible', title: 'Eleceed', dateAddedAt: new Date(now - 10000) },
      { userId: 'late', title: 'Eleceed', dateAddedAt: new Date(now + 10000) },
    ]);
    notifications.preferences.mockResolvedValue({ libraryUpdates: true });
    expect(await service.checkManga('source', 'manga')).toEqual({ added: 2, notified: 1 });
    expect(notifications.create).toHaveBeenCalledWith(expect.objectContaining({
      userId: 'eligible', title: '2 new chapters of Eleceed', data: { chapterIds: ['new-1', 'new-2'] },
    }));
  });

  it('retains its snapshot during an empty source response', async () => {
    sources.getChapterList.mockResolvedValue([]);
    await expect(service.checkManga('source', 'manga')).rejects.toThrow('Empty chapter list');
    expect(prisma.chapterSnapshot.upsert).not.toHaveBeenCalled();
  });
});
