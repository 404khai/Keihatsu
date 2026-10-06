export type Analytics = {
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
