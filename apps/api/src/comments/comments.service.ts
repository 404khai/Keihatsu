import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { accountBadge } from '../auth/account-badge';
import { compressCommentImage } from './comment-image';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { NotificationsService } from '../notifications/notifications.service';
import { notificationLinks } from '../notifications/notification-links';
import { NotificationType } from '@prisma/client';

@Injectable()
export class CommentsService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
    private notifications: NotificationsService,
  ) {}

  async create(
    userId: string,
    sourceId: string,
    mangaId: string,
    chapterId: string,
    createCommentDto: CreateCommentDto = {},
    files: Express.Multer.File[] = [],
  ) {
    if (createCommentDto.parentId) {
      const parent = await this.prisma.comment.findFirst({
        where: {
          id: createCommentDto.parentId,
          sourceId,
          mangaId,
          chapterId,
        },
        select: { id: true, userId: true, parentId: true },
      });
      if (!parent) {
        throw new BadRequestException('Reply parent is not in this thread');
      }
    }

    const uploadPromises = files.map(async (file) =>
      this.cloudinary.uploadImage(await compressCommentImage(file), 'keihatsu-comments'),
    );

    const uploadResults = await Promise.all(uploadPromises);
    const imageUrls = uploadResults.map((result) => result.secure_url);

    const comment = await this.prisma.comment.create({
      data: {
        content: createCommentDto.content || '',
        images: imageUrls,
        userId,
        sourceId,
        mangaId,
        chapterId,
        parentId: createCommentDto.parentId || null,
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            role: true,
            avatarHue: true,
            avatarShape: true,
            avatarExpression: true,
            avatarAnimated: true,
          },
        },
      },
    });
    const link = notificationLinks.comment(sourceId, mangaId, chapterId, comment.id);
    if (createCommentDto.parentId) {
      const parent = await this.prisma.comment.findUnique({ where: { id: createCommentDto.parentId },
        select: { userId: true, parentId: true } });
      if (parent && parent.userId !== userId) {
        await this.notifications.create({ userId: parent.userId, type: NotificationType.COMMENT_REPLY,
          title: `${comment.user.username} replied to your comment`, body: 'Open the conversation to read the reply.',
          actorUserId: userId, sourceId, mangaId, chapterId, commentId: comment.id,
          threadId: parent.parentId || createCommentDto.parentId,
          deepLink: link, groupingKey: `thread:${parent.parentId || createCommentDto.parentId}`,
          dedupeKey: `reply:${comment.id}` });
      }
    }
    const mentioned = [...new Set([...(comment.content || '').matchAll(/@(?:\{([A-Za-z0-9_]{1,32})\}|([A-Za-z0-9_]{1,32}))/g)]
      .map((match) => match[1] || match[2]))];
    if (mentioned.length) {
      const users = await this.prisma.user.findMany({ where: { username: { in: mentioned } },
        select: { id: true } });
      for (const mentionedUser of users) {
        if (mentionedUser.id === userId) continue;
        await this.notifications.create({ userId: mentionedUser.id, type: NotificationType.COMMENT_MENTION,
          title: `${comment.user.username} mentioned you`, body: 'Open the conversation to read the mention.',
          actorUserId: userId, sourceId, mangaId, chapterId, commentId: comment.id,
          threadId: createCommentDto.parentId || comment.id, deepLink: link,
          groupingKey: `thread:${createCommentDto.parentId || comment.id}`,
          dedupeKey: `mention:${comment.id}:${mentionedUser.id}` });
      }
    }
    return this.publicComment(comment);
  }

  async findAll(
    sourceId: string,
    mangaId: string,
    chapterId: string,
    userId?: string,
  ) {
    const includeLike = userId
      ? {
          where: { userId },
          select: { id: true },
        }
      : false;

    // Helper to build include object for recursion
    const buildInclude = (depth: number): any => {
      if (depth === 0) return {
        user: { select: { id: true, username: true, email: true, role: true,
          avatarHue: true, avatarShape: true, avatarExpression: true, avatarAnimated: true } },
      };
      return {
        user: {
          select: {
            id: true,
            username: true,
            email: true,
            role: true,
            avatarHue: true,
            avatarShape: true,
            avatarExpression: true,
            avatarAnimated: true,
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
        sourceId,
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
            email: true,
            role: true,
            avatarHue: true,
            avatarShape: true,
            avatarExpression: true,
            avatarAnimated: true,
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
    return comments.map((comment) => this.publicComment(comment));
  }

  private publicComment(comment: any): any {
    if (!comment) return comment;
    const { user, replies, ...fields } = comment;
    const { email, role, ...publicUser } = user || {};
    return {
      ...fields,
      ...(user ? { user: { ...publicUser, profileBadge: accountBadge({ email, role }) } } : {}),
      ...(replies ? { replies: replies.map((reply: any) => this.publicComment(reply)) } : {}),
    };
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
      const comment = await this.prisma.comment.findUnique({ where: { id: commentId },
        select: { userId: true, sourceId: true, mangaId: true, chapterId: true, parentId: true } });
      if (comment && comment.userId !== userId) {
        const actor = await this.prisma.user.findUnique({ where: { id: userId }, select: { username: true } });
        await this.notifications.recordLike({ ...comment, id: commentId }, userId, actor?.username || 'Someone');
      }
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
