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
  const service = new CommentsService(prisma as any, cloudinary as any);

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
