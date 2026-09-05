import 'package:isar/isar.dart';

part 'local_models.g.dart';

@collection
class LocalSource {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sourceId;

  late String name;
  late String lang;
  late String baseUrl;
  String? iconUrl;
  String? iconLocalPath;
  bool pinned = false;
  bool enabled = true;
  int versionId = 0;
  DateTime? lastUpdatedAt;
}

@collection
class LocalManga {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('sourceId'), CompositeIndex('ownerUserId')],
  )
  late String mangaId;
  late String sourceId;
  @Index()
  late String ownerUserId;

  late String title;
  String? description;
  String? thumbnailUrl;
  String? thumbnailLocalPath;
  String? author;
  String? artist;
  String? status;
  List<String>? genres;

  bool isFavorite = false;
  DateTime? lastReadAt;
}

@collection
class LocalChapter {
  Id id = Isar.autoIncrement;

  late String chapterId;
  late String mangaId;
  late String sourceId;
  @Index()
  late String ownerUserId;
  @Index(unique: true, replace: true)
  late String scopedChapterKey;

  late String name;
  late double chapterNumber;
  late int dateUpload;
  String? scanlator;

  bool downloaded = false;
  DateTime? lastReadAt;
  int? lastPageRead;
  bool isBookmarked = false;
  bool isRead = false;
}

@collection
class LocalPage {
  Id id = Isar.autoIncrement;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('index'), CompositeIndex('ownerUserId')],
  )
  late String chapterId;

  late int index;
  @Index()
  late String ownerUserId;
  String? imageLocalPath;
  late String imageRemoteUrl;
}

@collection
class LocalLibraryEntry {
  Id id = Isar.autoIncrement;

  @Index()
  String? serverId;

  @Index(
    unique: true,
    replace: true,
    composite: [CompositeIndex('sourceId'), CompositeIndex('ownerUserId')],
  )
  late String mangaId;
  late String sourceId;
  @Index()
  late String ownerUserId;

  bool isBookmarked = true;
  bool isCompleted = false;
  bool isUnread = true;
  bool isStarted = false;

  int downloadedCount = 0;
  int unreadCount = 0;
  int totalChapters = 0;

  DateTime? lastReadAt;
  DateTime? lastUpdatedAt;
  DateTime? dateAddedAt;

  // Snapshot of manga metadata
  late String title;
  String? thumbnailUrl;
  String? author;
  String? language;
}

@collection
class LocalCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? serverId; // null if not synced yet

  @Index(unique: true, replace: true, composite: [CompositeIndex('ownerUserId')])
  late String name;
  @Index()
  late String ownerUserId;
  bool isSynced = false;
}

@collection
class LocalCategoryAssignment {
  Id id = Isar.autoIncrement;

  late String mangaId;
  @Index()
  late String sourceId;
  @Index()
  late int localCategoryId; // Links to LocalCategory.id
  @Index()
  late String ownerUserId;
  @Index(unique: true, replace: true)
  late String scopedAssignmentKey;
}

@collection
class SyncOperation {
  Id id = Isar.autoIncrement;

  late String type; // 'ADD_LIBRARY', 'REMOVE_LIBRARY', 'CREATE_CATEGORY', etc.
  late String payload; // JSON string
  late DateTime timestamp;
  @Index()
  late String ownerUserId;

  @Index()
  bool completed = false;
  int retryCount = 0;
  String? errorMessage;
}

@collection
class LocalUserPreferences {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String ownerUserId;
  String libraryDisplayStyle = 'grid'; // 'grid' or 'list'
  String categoriesDisplayMode = 'comfortable grid';
  int libraryItemsPerRow = 3;
  bool overlayShowDownloaded = true;
  bool overlayShowUnread = true;
  bool overlayShowLanguage = true;
  bool tabsShowCategories = true;
  bool tabsShowItemCount = true;

  late String sourcePreferencesJson; // Store as JSON string for simplicity
}

@collection
class DownloadQueueItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String chapterId;

  @Index()
  late String mangaId;

  @Index()
  late String sourceId;

  late String chapterName;
  late double chapterNumber;
  late String mangaTitle;
  String? mangaThumbnail;
  late String extensionName;

  // 0: Queued, 1: Downloading, 2: Completed, 3: Failed, 4: Paused
  int status = 0;
  double progress = 0.0;
  int priority = 0;
  DateTime dateAdded = DateTime.now();
  String? error;
}
