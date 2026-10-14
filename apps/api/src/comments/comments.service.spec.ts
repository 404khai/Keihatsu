import { CommentsService } from './comments.service';

describe('CommentsService source scoping', () => {
  const prisma = {
    comment: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
    },
  };
  const cloudinary = { uploadImage: jest.fn() };
  const notifications = { create: jest.fn(), recordLike: jest.fn() };
  const service = new CommentsService(prisma as any, cloudinary as any, notifications as any);

  beforeEach(() => jest.clearAllMocks());

  it('reads a thread by source, manga, and chapter', async () => {
    prisma.comment.findMany.mockResolvedValue([]);

    await service.findAll(
      'weebcentral',
      'shared-manga-id',
      'chapter-1',
      'user-1',
    );

    expect(prisma.comment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          sourceId: 'weebcentral',
          mangaId: 'shared-manga-id',
          chapterId: 'chapter-1',
        }),
      }),
    );
  });

  it('returns trusted badges at every reply level without private identity fields', async () => {
    const reader = { id: 'reader', username: '404khai', email: 'reader@example.com', role: 'USER' };
    const tester = { id: 'tester', username: 'beta', email: 'dexgamingacct@gmail.com', role: 'USER' };
    const developer = { id: 'dev', username: 'khai', email: '404khai@gmail.com', role: 'ADMIN' };
    prisma.comment.findMany.mockResolvedValue([
      { id: 'root', user: developer, replies: [
        { id: 'reply', user: tester, replies: [{ id: 'leaf', user: reader }] },
      ] },
    ]);
    const result = await service.findAll('source', 'manga', 'chapter');
    expect(result[0].user.profileBadge).toBe('developer');
    expect(result[0].replies[0].user.profileBadge).toBe('android_beta_tester');
    expect(result[0].replies[0].replies[0].user.profileBadge).toBeNull();
    expect(JSON.stringify(result)).not.toContain('email');
    expect(JSON.stringify(result)).not.toContain('role');
    expect(prisma.comment.findMany.mock.calls[0][0].include.replies.include.replies.include.replies.include.replies.include.user.select.email).toBe(true);
  });

  it('writes the source identity into new comments', async () => {
    prisma.comment.create.mockResolvedValue({ id: 'comment-1' });

    await service.create(
      'user-1',
      'weebcentral',
      'manga-1',
      'chapter-1',
      { content: 'Hello' },
    );

    expect(prisma.comment.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ sourceId: 'weebcentral' }),
      }),
    );
  });
});
