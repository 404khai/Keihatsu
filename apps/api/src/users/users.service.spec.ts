import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

describe('UsersService', () => {
  let service: UsersService;
  const prismaService = {
    user: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: prismaService },
        { provide: CloudinaryService, useValue: {} },
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
});
