import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  ConflictException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User, Prisma } from '@prisma/client';
import { UpdateUserPreferencesDto } from './dto/user-preferences.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

import { UserStatsDto } from './dto/user-stats.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private prisma: PrismaService,
    private cloudinaryService: CloudinaryService,
  ) {}

  async getUserStats(userId: string): Promise<UserStatsDto> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Library Count
    const libraryCount = await this.prisma.libraryEntry.count({
      where: { userId },
    });

    // 2. Comments (Total)
    const commentsCount = await this.prisma.comment.count({
      where: {
        userId,
      },
    });

    // 3. Mangas Read Today (Unique mangas read today)
    const distinctMangas = await this.prisma.historyEntry.groupBy({
      by: ['mangaId'],
      where: {
        userId,
        lastReadAt: { gte: today },
      },
    });
    const mangasReadToday = distinctMangas.length;

    // 4. Total Reading Time
    // Calculate total reading time from all entries in readingStats
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { readingStats: true, points: true },
    });

    let totalReadingTimeMinutes = 0;
    if (user?.readingStats) {
      const stats = user.readingStats as Record<string, number>;
      const totalMs = Object.values(stats).reduce(
        (acc, curr) => acc + (typeof curr === 'number' ? curr : 0),
        0,
      );
      totalReadingTimeMinutes = Math.floor(totalMs / 60000);
    }

    return {
      libraryCount,
      commentsCount,
      mangasReadToday,
      totalReadingTimeMinutes,
      points: user?.points || 0,
    };
  }

  async findOne(
    userWhereUniqueInput: Prisma.UserWhereUniqueInput,
  ): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: userWhereUniqueInput,
    });
  }

  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { googleId },
    });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async createGoogleUser(data: {
    googleId: string;
    email: string;
    displayName: string;
  }): Promise<User> {
    const baseUsername = data.email.split('@')[0];
    let username = baseUsername;
    let counter = 1;

    while (await this.prisma.user.findUnique({ where: { username } })) {
      username = `${baseUsername}${counter}`;
      counter++;
    }

    return this.prisma.user.create({
      data: {
        googleId: data.googleId,
        email: data.email,
        username,
        isOnboarded: false,
      },
    });
  }

  async updateUser(params: {
    where: Prisma.UserWhereUniqueInput;
    data: Prisma.UserUpdateInput;
  }): Promise<User> {
    const { where, data } = params;
    return this.prisma.user.update({
      data,
      where,
    });
  }

  async getPreferences(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { preferences: true },
    });
    return user?.preferences || {};
  }

  async updatePreferences(
    userId: string,
    preferencesDto: UpdateUserPreferencesDto,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { preferences: true },
    });

    const currentPreferences = (user?.preferences as object) || {};
    const newPreferences = { ...currentPreferences, ...preferencesDto };

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        preferences: newPreferences,
      },
      select: { preferences: true },
    });
  }

  async updateProfileVisibility(userId: string, isProfilePublic: boolean) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { isProfilePublic },
    });
  }

  async getPublicProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        username: true,
        avatarUrl: true,
        avatarHue: true,
        avatarShape: true,
        avatarExpression: true,
        avatarAnimated: true,
        bannerUrl: true,
        bio: true,
        createdAt: true,
        isProfilePublic: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const stats = await this.getUserStats(userId);
    const library = user.isProfilePublic
      ? await this.prisma.libraryEntry.findMany({
          where: { userId },
          orderBy: [{ lastReadAt: 'desc' }, { dateAddedAt: 'desc' }],
          select: {
            id: true,
            mangaId: true,
            sourceId: true,
            title: true,
            thumbnailUrl: true,
            author: true,
            totalChapters: true,
            lastReadAt: true,
            dateAddedAt: true,
          },
        })
      : [];

    return {
      ...user,
      stats: {
        ...stats,
        libraryCount: user.isProfilePublic ? stats.libraryCount : 0,
      },
      library,
    };
  }

  async updateProfile(
    userId: string,
    updateDto: UpdateUserProfileDto,
    files: { avatar?: Express.Multer.File[]; banner?: Express.Multer.File[] },
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new BadRequestException('User not found');

    const updateData: Prisma.UserUpdateInput = {};
    let newAvatarUrl: string | undefined;
    let newBannerUrl: string | undefined;

    // 1. Handle Username Update with Limits
    if (updateDto.username && updateDto.username !== user.username) {
      // Check limits
      const now = new Date();
      const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

      let updateCount = user.usernameUpdateCount;
      const lastUpdate = user.usernameUpdatedAt;

      // If last update was more than 7 days ago, reset count
      if (!lastUpdate || lastUpdate < sevenDaysAgo) {
        updateCount = 0;
      }

      if (updateCount >= 2) {
        throw new ForbiddenException(
          'Username can only be changed 2 times every 7 days.',
        );
      }

      // Check uniqueness
      const existingUser = await this.prisma.user.findUnique({
        where: { username: updateDto.username },
      });
      if (existingUser) {
        throw new ConflictException('Username is already taken.');
      }

      updateData.username = updateDto.username;
      updateData.usernameUpdateCount = updateCount + 1;
      updateData.usernameUpdatedAt = now;
    }

    // 2. Handle Bio
    if (updateDto.bio !== undefined) {
      updateData.bio = updateDto.bio;
    }

    if (updateDto.avatarHue !== undefined) {
      if (updateDto.avatarHue === 'auto') {
        updateData.avatarHue = null;
      } else {
        const hue = Number(updateDto.avatarHue);
        if (!Number.isFinite(hue) || hue < 0 || hue >= 360) {
          throw new BadRequestException('Avatar hue must be between 0 and 359.');
        }
        updateData.avatarHue = hue;
      }
    }

    if (updateDto.avatarShape !== undefined) {
      if (updateDto.avatarShape === 'auto') {
        updateData.avatarShape = null;
      } else {
        const shape = Number(updateDto.avatarShape);
        if (!Number.isFinite(shape) || shape < 0 || shape >= 1) {
          throw new BadRequestException(
            'Avatar shape must be between 0 and 0.999.',
          );
        }
        updateData.avatarShape = shape;
      }
    }

    if (updateDto.avatarExpression !== undefined) {
      updateData.avatarExpression = updateDto.avatarExpression;
    }

    if (updateDto.avatarAnimated !== undefined) {
      updateData.avatarAnimated = updateDto.avatarAnimated === 'true';
    }

    if (files.avatar && files.avatar.length > 0) {
      const result = await this.cloudinaryService.uploadImage(
        files.avatar[0],
        'avatars',
      );
      newAvatarUrl = result.secure_url;
      updateData.avatarUrl = newAvatarUrl;
    }

    if (files.banner && files.banner.length > 0) {
      const result = await this.cloudinaryService.uploadImage(
        files.banner[0],
        'banners',
      );
      newBannerUrl = result.secure_url;
      updateData.bannerUrl = newBannerUrl;
    }

    let updatedUser: User;

    try {
      updatedUser = await this.prisma.user.update({
        where: { id: userId },
        data: updateData,
      });
    } catch (error) {
      await Promise.allSettled([
        newAvatarUrl
          ? this.cloudinaryService.deleteImageByUrl(newAvatarUrl)
          : Promise.resolve(false),
        newBannerUrl
          ? this.cloudinaryService.deleteImageByUrl(newBannerUrl)
          : Promise.resolve(false),
      ]);

      throw error;
    }

    const cleanupTasks: Promise<boolean>[] = [];

    if (newAvatarUrl && user.avatarUrl && user.avatarUrl !== newAvatarUrl) {
      cleanupTasks.push(
        this.cloudinaryService.deleteImageByUrl(user.avatarUrl),
      );
    }

    if (newBannerUrl && user.bannerUrl && user.bannerUrl !== newBannerUrl) {
      cleanupTasks.push(
        this.cloudinaryService.deleteImageByUrl(user.bannerUrl),
      );
    }

    const cleanupResults = await Promise.allSettled(cleanupTasks);
    cleanupResults.forEach((result) => {
      if (result.status === 'rejected') {
        this.logger.warn(
          `Failed to delete replaced Cloudinary asset: ${result.reason instanceof Error ? result.reason.message : String(result.reason)}`,
        );
      }
    });

    return updatedUser;
  }
}
