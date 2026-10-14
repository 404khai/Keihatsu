export type Analytics = {
  engagement: {
    onboardedUsers: number;
    weeklyActiveReaders: number;
    readingMinutes7Days: number;
  };
  generatedAt: string;
  totalUsers: number;
  activeReaders: number;
  newUsers: number;
  comments: number;
  library: number;
  history: number;
  growth: { date: string; users: number }[];
  platforms: { platform: string; devices: number }[];
  sources: {
    sourceId: string;
    failureCount: number;
    lastSuccessAt: string | null;
    lastFailureAt: string | null;
    outageAnnouncedAt: string | null;
  }[];
  recentSignups: {
    id: string;
    username: string;
    email: string;
    createdAt: string;
    isOnboarded: boolean;
    role: string;
  }[];
};

export type Administrator = {
  id: string;
  username: string;
  email: string;
  createdAt: string;
  role: "ADMIN";
};
export type Announcement = {
  id: string;
  title: string;
  body: string;
  severity: string;
  pushEnabled: boolean;
  publishAt: string;
  publishedAt: string | null;
  expiresAt: string | null;
  createdAt: string;
  platform: string | null;
  minAppVersion: string | null;
  maxAppVersion: string | null;
};
