import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

describe('UsersService', () => {
  let service: UsersService;
  const transaction = {
    comment: {
      findMany: jest.fn(),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    commentLike: { deleteMany: jest.fn() },
    historySyncEvent: { deleteMany: jest.fn() },
    historyEntry: { deleteMany: jest.fn() },
    libraryEntry: { deleteMany: jest.fn() },
    category: { deleteMany: jest.fn() },
    user: { delete: jest.fn() },
  };
  const prismaService = {
    user: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(
      (callback: (value: typeof transaction) => Promise<void>) =>
        callback(transaction),
    ),
  };
  const cloudinaryService = { deleteImageByUrl: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: prismaService },
        { provide: CloudinaryService, useValue: cloudinaryService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('looks up Google account emails case-insensitively', async () => {
    const user = { id: 'user-1', email: 'reader@example.com' };
    prismaService.user.findFirst.mockResolvedValue(user);

    await expect(service.findByEmail(' Reader@Example.com ')).resolves.toBe(
      user,
    );
    expect(prismaService.user.findFirst).toHaveBeenCalledWith({
      where: {
        email: {
          equals: 'reader@example.com',
          mode: 'insensitive',
        },
      },
    });
  });

  it('deletes authenticated account data and uploaded profile assets', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      avatarUrl:
        'https://res.cloudinary.com/demo/image/upload/v1/avatars/a.png',
      bannerUrl:
        'https://res.cloudinary.com/demo/image/upload/v1/banners/b.png',
    });
    transaction.comment.findMany.mockResolvedValue([{ id: 'comment-1' }]);
    cloudinaryService.deleteImageByUrl.mockResolvedValue(true);

    await service.deleteAccount('user-1');

    expect(transaction.comment.updateMany).toHaveBeenCalledWith({
      where: { parentId: { in: ['comment-1'] } },
      data: { parentId: null },
    });
    expect(transaction.commentLike.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
    });
    expect(transaction.historyEntry.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
    });
    expect(transaction.libraryEntry.deleteMany).toHaveBeenCalledWith({
      where: { userId: 'user-1' },
    });
    expect(transaction.user.delete).toHaveBeenCalledWith({
      where: { id: 'user-1' },
    });
    expect(cloudinaryService.deleteImageByUrl).toHaveBeenCalledWith(
      expect.stringContaining('/avatars/a.png'),
    );
    expect(cloudinaryService.deleteImageByUrl).toHaveBeenCalledWith(
      expect.stringContaining('/banners/b.png'),
    );
  });
});
