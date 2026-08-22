import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AdminStatsDto } from './dto/admin-stats.dto';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats(): Promise<AdminStatsDto> {
    const now = new Date();
    const todayStart = new Date(now.setHours(0, 0, 0, 0));
    const weekStart = new Date(new Date().setDate(now.getDate() - 7));

    // 1. User Counts
    const totalUsers = await this.prisma.user.count();
    const newUsersToday = await this.prisma.user.count({
      where: { createdAt: { gte: todayStart } },
    });
    const newUsersWeek = await this.prisma.user.count({
      where: { createdAt: { gte: weekStart } },
    });

    // 2. Platform Distribution (Inferred from preferences for now)
    // We'll look for a 'platform' key in user preferences JSON
    // If not found, we'll categorize as 'other'
    const users = await this.prisma.user.findMany({
      select: { preferences: true },
    });

    const platformDistribution = {
      web: 0,
      android: 0,
      other: 0,
    };

    users.forEach((user) => {
      const prefs = user.preferences as any;
      const platform = prefs?.platform?.toLowerCase();
      if (platform === 'web') platformDistribution.web++;
      else if (platform === 'android') platformDistribution.android++;
      else platformDistribution.other++;
    });

    // 3. Activity Stats
    const totalComments = await this.prisma.comment.count();
    const totalLibraryEntries = await this.prisma.libraryEntry.count();
    const totalHistoryEntries = await this.prisma.historyEntry.count();

    return {
      totalUsers,
      newUsersToday,
      newUsersWeek,
      platformDistribution,
      activityStats: {
        totalComments,
        totalLibraryEntries,
        totalHistoryEntries,
      },
    };
  }
}
