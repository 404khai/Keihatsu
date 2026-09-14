import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { CommentsController } from './comments.controller';
import { CommentsService } from './comments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OptionalJwtAuthGuard } from '../auth/guards/optional-jwt-auth.guard';

describe('CommentsController routing', () => {
  let app: INestApplication;
  const commentsService = {
    create: jest.fn(),
    findAll: jest.fn(),
    like: jest.fn(),
    remove: jest.fn(),
  };
  const authenticatedGuard = {
    canActivate: (context: any) => {
      context.switchToHttp().getRequest().user = { id: 'user-1' };
      return true;
    },
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [CommentsController],
      providers: [{ provide: CommentsService, useValue: commentsService }],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(authenticatedGuard)
      .overrideGuard(OptionalJwtAuthGuard)
      .useValue(authenticatedGuard)
      .compile();

    app = module.createNestApplication();
    await app.init();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    commentsService.like.mockResolvedValue({ status: 'added' });
  });

  afterAll(async () => {
    await app.close();
  });

  it.each(['/comments/like/comment-1', '/comments/comment-1/like'])(
    'routes %s to the like handler rather than comment creation',
    async (path) => {
      await request(app.getHttpServer()).post(path).expect(201);

      expect(commentsService.like).toHaveBeenCalledWith('user-1', 'comment-1');
      expect(commentsService.create).not.toHaveBeenCalled();
    },
  );
});
