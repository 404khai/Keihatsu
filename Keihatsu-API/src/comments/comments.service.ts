import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class CommentsService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
  ) {}

  async create(
    userId: string,
    mangaId: string,
    chapterId: string,
    createCommentDto: CreateCommentDto,
    files: Express.Multer.File[] = [],
  ) {
    const uploadPromises = files.map((file) =>
      this.cloudinary.uploadImage(file, 'keihatsu-comments'),
    );

    const uploadResults = await Promise.all(uploadPromises);
    const imageUrls = uploadResults.map((result) => result.secure_url);

    return this.prisma.comment.create({
      data: {
        content: createCommentDto.content || '',
        images: imageUrls,
        userId,
        mangaId,
        chapterId,
        parentId: createCommentDto.parentId || null,
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async findAll(mangaId: string, chapterId: string, userId?: string) {
    const includeLike = userId
      ? {
          where: { userId },
          select: { id: true },
        }
      : false;

    // Helper to build include object for recursion
    const buildInclude = (depth: number): any => {
      if (depth === 0) return {};
      return {
        user: {
          select: {
            id: true,
            username: true,
            avatarUrl: true,
          },
        },
        userLikes: includeLike,
        _count: {
          select: { replies: true },
        },
        replies: {
          include: buildInclude(depth - 1),
          orderBy: { createdAt: 'asc' }, // Replies usually asc
        },
      };
    };

    // Fetching top-level comments with up to 3 levels of nesting
    const comments = await this.prisma.comment.findMany({
      where: {
        mangaId,
        chapterId,
        parentId: null, // Only fetch root comments
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            avatarUrl: true,
          },
        },
        userLikes: includeLike,
        _count: {
          select: { replies: true },
        },
        replies: {
          include: buildInclude(3),
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    // If we need to flatten or transform to add 'userVote' field, we can do it here.
    // If we need to flatten or transform to add 'userLike' field, we can do it here.
    // But returning the 'userLikes' array is fine for frontend to parse.
    // Frontend logic: isLiked = comment.userLikes.length > 0
    return comments;
  }

  async like(userId: string, commentId: string) {
    const existingLike = await this.prisma.commentLike.findUnique({
      where: {
        userId_commentId: {
          userId,
          commentId,
        },
      },
    });

    if (existingLike) {
      // Toggle off (remove like)
      await this.prisma.commentLike.delete({
        where: { id: existingLike.id },
      });
      // Decrement count
      await this.prisma.comment.update({
        where: { id: commentId },
        data: {
          likes: { decrement: 1 },
        },
      });
      return { status: 'removed' };
    } else {
      // Create new like
      await this.prisma.commentLike.create({
        data: {
          userId,
          commentId,
        },
      });
      // Increment count
      await this.prisma.comment.update({
        where: { id: commentId },
        data: {
          likes: { increment: 1 },
        },
      });
      return { status: 'added' };
    }
  }

  async remove(id: string, userId: string) {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    if (comment.userId !== userId) {
      throw new ForbiddenException('You can only delete your own comments');
    }

    return this.prisma.comment.delete({
      where: { id },
    });
  }
}
