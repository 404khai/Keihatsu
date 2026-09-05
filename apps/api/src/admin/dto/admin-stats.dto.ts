export class AdminStatsDto {
  totalUsers: number;
  newUsersToday: number;
  newUsersWeek: number;
  platformDistribution: {
    web: number;
    android: number;
    other: number;
  };
  activityStats: {
    totalComments: number;
    totalLibraryEntries: number;
    totalHistoryEntries: number;
  };
}
