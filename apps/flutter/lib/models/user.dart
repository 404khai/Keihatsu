class User {
  final String id;
  final String? googleId;
  final String? email;
  final String? avatarUrl;
  final double? avatarHue;
  final double? avatarShape;
  final String avatarExpression;
  final bool avatarAnimated;
  final String? bannerUrl;
  final String? username;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isOnboarded;
  final bool isProfilePublic;
  final dynamic readingStats;
  final int achievementCount;
  final int points;
  final UserStats? stats;

  User({
    required this.id,
    this.googleId,
    this.email,
    this.avatarUrl,
    this.avatarHue,
    this.avatarShape,
    this.avatarExpression = 'happy',
    this.avatarAnimated = false,
    this.bannerUrl,
    this.username,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isOnboarded = false,
    this.isProfilePublic = true,
    this.readingStats,
    this.achievementCount = 0,
    this.points = 0,
    this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      googleId: json['googleId'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      avatarHue: (json['avatarHue'] as num?)?.toDouble(),
      avatarShape: (json['avatarShape'] as num?)?.toDouble(),
      avatarExpression: json['avatarExpression'] ?? 'happy',
      avatarAnimated: json['avatarAnimated'] ?? false,
      bannerUrl: json['bannerUrl'],
      username: json['username'],
      bio: json['bio'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isOnboarded: json['isOnboarded'] ?? false,
      isProfilePublic: json['isProfilePublic'] ?? true,
      readingStats: json['readingStats'],
      achievementCount: json['achievementCount'] ?? 0,
      points: json['points'] ?? 0,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'googleId': googleId,
      'email': email,
      'avatarUrl': avatarUrl,
      'avatarHue': avatarHue,
      'avatarShape': avatarShape,
      'avatarExpression': avatarExpression,
      'avatarAnimated': avatarAnimated,
      'bannerUrl': bannerUrl,
      'username': username,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isOnboarded': isOnboarded,
      'isProfilePublic': isProfilePublic,
      'readingStats': readingStats,
      'achievementCount': achievementCount,
      'points': points,
      'stats': stats?.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? googleId,
    String? email,
    String? avatarUrl,
    double? avatarHue,
    double? avatarShape,
    String? avatarExpression,
    bool? avatarAnimated,
    String? bannerUrl,
    String? username,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isOnboarded,
    bool? isProfilePublic,
    dynamic readingStats,
    int? achievementCount,
    int? points,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      googleId: googleId ?? this.googleId,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarHue: avatarHue ?? this.avatarHue,
      avatarShape: avatarShape ?? this.avatarShape,
      avatarExpression: avatarExpression ?? this.avatarExpression,
      avatarAnimated: avatarAnimated ?? this.avatarAnimated,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      readingStats: readingStats ?? this.readingStats,
      achievementCount: achievementCount ?? this.achievementCount,
      points: points ?? this.points,
      stats: stats ?? this.stats,
    );
  }
}

class UserStats {
  final int libraryCount;
  final int totalReadingTimeMinutes;
  final int mangasReadToday;
  final int commentsCount;
  final int points;

  UserStats({
    required this.libraryCount,
    required this.totalReadingTimeMinutes,
    required this.mangasReadToday,
    required this.commentsCount,
    required this.points,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      libraryCount: json['libraryCount'] ?? 0,
      totalReadingTimeMinutes: json['totalReadingTimeMinutes'] ?? 0,
      mangasReadToday: json['mangasReadToday'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'libraryCount': libraryCount,
      'totalReadingTimeMinutes': totalReadingTimeMinutes,
      'mangasReadToday': mangasReadToday,
      'commentsCount': commentsCount,
      'points': points,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      user: User.fromJson(json['user']),
    );
  }
}

class PublicLibraryEntry {
  final String id;
  final String mangaId;
  final String sourceId;
  final String title;
  final String? thumbnailUrl;
  final String? author;
  final int totalChapters;
  final DateTime? lastReadAt;
  final DateTime? dateAddedAt;

  PublicLibraryEntry({
    required this.id,
    required this.mangaId,
    required this.sourceId,
    required this.title,
    this.thumbnailUrl,
    this.author,
    this.totalChapters = 0,
    this.lastReadAt,
    this.dateAddedAt,
  });

  factory PublicLibraryEntry.fromJson(Map<String, dynamic> json) {
    return PublicLibraryEntry(
      id: json['id'] ?? '',
      mangaId: json['mangaId'] ?? '',
      sourceId: json['sourceId'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      author: json['author'],
      totalChapters: json['totalChapters'] ?? 0,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'])
          : null,
      dateAddedAt: json['dateAddedAt'] != null
          ? DateTime.parse(json['dateAddedAt'])
          : null,
    );
  }
}

class PublicProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final double? avatarHue;
  final double? avatarShape;
  final String avatarExpression;
  final bool avatarAnimated;
  final String? bannerUrl;
  final String? bio;
  final bool isProfilePublic;
  final DateTime? createdAt;
  final UserStats? stats;
  final List<PublicLibraryEntry> library;

  PublicProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.avatarHue,
    this.avatarShape,
    this.avatarExpression = 'happy',
    this.avatarAnimated = false,
    this.bannerUrl,
    this.bio,
    this.isProfilePublic = true,
    this.createdAt,
    this.stats,
    this.library = const [],
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      avatarHue: (json['avatarHue'] as num?)?.toDouble(),
      avatarShape: (json['avatarShape'] as num?)?.toDouble(),
      avatarExpression: json['avatarExpression'] ?? 'happy',
      avatarAnimated: json['avatarAnimated'] ?? false,
      bannerUrl: json['bannerUrl'],
      bio: json['bio'],
      isProfilePublic: json['isProfilePublic'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      stats: json['stats'] != null ? UserStats.fromJson(json['stats']) : null,
      library: (json['library'] as List<dynamic>? ?? [])
          .map((entry) => PublicLibraryEntry.fromJson(entry))
          .toList(),
    );
  }
}
