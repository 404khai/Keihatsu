import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_models.dart';
import '../models/manga.dart';
import 'library_api.dart';
import 'sync_manager.dart';

class LibraryRepository {
  final Isar isar;
  final LibraryApi api;
  final SyncManager syncManager;
  final String Function() getCurrentUserId;

  LibraryRepository({
    required this.isar,
    required this.api,
    required this.syncManager,
    required this.getCurrentUserId,
  });

  String get _currentUserId => getCurrentUserId();

  String _assignmentScopedKey(
      String mangaId,
      String sourceId,
      int localCategoryId,
      String ownerUserId,
      ) {
    return '$ownerUserId::$sourceId::$mangaId::$localCategoryId';
  }

  Stream<List<LocalLibraryEntry>> watchLibrary() {
    return isar.collection<LocalLibraryEntry>().where().watch(
      fireImmediately: true,
    );
  }

  Stream<List<LocalCategoryAssignment>> watchCategoryAssignments() {
    return isar.collection<LocalCategoryAssignment>().where().watch(
      fireImmediately: true,
    );
  }

  Stream<List<LocalCategory>> watchCategories() {
    return isar.collection<LocalCategory>().where().watch(
      fireImmediately: true,
    );
  }

  Future<List<LocalLibraryEntry>> getLibrary({
    bool forceRefresh = false,
    String? token,
    bool? filterDownloaded,
    bool? filterUnread,
    bool? filterStarted,
    bool? filterBookmarked,
    bool? filterCompleted,
    String? sortBy,
    String? order,
    String? search,
  }) async {
    if (forceRefresh && token != null) {
      await refreshLibrary(
        token: token,
        filterDownloaded: filterDownloaded,
        filterUnread: filterUnread,
        filterStarted: filterStarted,
        filterBookmarked: filterBookmarked,
        filterCompleted: filterCompleted,
        sortBy: sortBy,
        order: order,
        search: search,
      );
    }

    return await isar
        .collection<LocalLibraryEntry>()
        .filter()
        .ownerUserIdEqualTo(_currentUserId)
        .findAll();
  }

  Future<void> refreshLibrary({
    required String token,
    bool? filterDownloaded,
    bool? filterUnread,
    bool? filterStarted,
    bool? filterBookmarked,
    bool? filterCompleted,
    String? sortBy,
    String? order,
    String? search,
  }) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final response = await api.getLibrary(
        token: token,
        filterDownloaded: filterDownloaded,
        filterUnread: filterUnread,
        filterStarted: filterStarted,
        filterBookmarked: filterBookmarked,
        filterCompleted: filterCompleted,
        sortBy: sortBy,
        order: order,
        search: search,
      );

      if (response.statusCode == 200) {
        final List<dynamic> remoteData = json.decode(response.body);

        await isar.writeTxn(() async {
          for (var item in remoteData) {
            final mangaId = item['mangaId'];
            final sourceId = item['sourceId'];

            var entry =
                await isar
                    .collection<LocalLibraryEntry>()
                    .filter()
                    .mangaIdEqualTo(mangaId)
                    .sourceIdEqualTo(sourceId)
                    .ownerUserIdEqualTo(_currentUserId)
                    .findFirst() ??
                    LocalLibraryEntry();

            entry
              ..serverId = item['id']
              ..mangaId = mangaId
              ..sourceId = sourceId
              ..ownerUserId = _currentUserId
              ..title = item['title']
              ..thumbnailUrl = item['thumbnailUrl']
              ..author = item['author']
              ..language = item['language']
              ..isBookmarked = item['isBookmarked'] ?? true
              ..isUnread = item['isUnread'] ?? true
              ..isStarted = item['isStarted'] ?? false
              ..isCompleted = item['isCompleted'] ?? false
              ..downloadedCount = item['downloadedCount'] ?? 0
              ..unreadCount = item['unreadCount'] ?? 0
              ..totalChapters = item['totalChapters'] ?? 0
              ..lastReadAt = item['lastReadAt'] != null
                  ? DateTime.parse(item['lastReadAt'])
                  : null
              ..lastUpdatedAt = item['lastUpdatedAt'] != null
                  ? DateTime.parse(item['lastUpdatedAt'])
                  : null
              ..dateAddedAt = item['dateAddedAt'] != null
                  ? DateTime.parse(item['dateAddedAt'])
                  : null;

            await isar.collection<LocalLibraryEntry>().put(entry);

            if (item['categories'] != null) {
              final List<dynamic> categories = item['categories'];
              await isar
                  .collection<LocalCategoryAssignment>()
                  .filter()
                  .mangaIdEqualTo(mangaId)
                  .sourceIdEqualTo(sourceId)
                  .ownerUserIdEqualTo(_currentUserId)
                  .deleteAll();

              for (var catData in categories) {
                final serverCatId = catData['id'];
                var localCat = await isar
                    .collection<LocalCategory>()
                    .filter()
                    .serverIdEqualTo(serverCatId)
                    .ownerUserIdEqualTo(_currentUserId)
                    .findFirst();

                if (localCat == null) {
                  localCat = LocalCategory()
                    ..serverId = serverCatId
                    ..name = catData['name']
                    ..ownerUserId = _currentUserId
                    ..isSynced = true;
                  await isar.collection<LocalCategory>().put(localCat);
                }

                final assignment = LocalCategoryAssignment()
                  ..mangaId = mangaId
                  ..sourceId = sourceId
                  ..ownerUserId = _currentUserId
                  ..scopedAssignmentKey = _assignmentScopedKey(
                    mangaId,
                    sourceId,
                    localCat.id,
                    _currentUserId,
                  )
                  ..localCategoryId = localCat.id;
                await isar.collection<LocalCategoryAssignment>().put(
                  assignment,
                );
              }
            }
          }
        });
      }
    } catch (e) {
      print('Failed to refresh library: $e');
    }
  }

  Future<void> addToLibrary(
      String token,
      Manga manga, {
        List<String>? categories,
      }) async {
    // We try to get total chapters if possible from local or basic info
    // However, manga object passed here might be minimal.
    // Ideally, we fetch details first or rely on next refresh.
    // For now, we set unreadCount to 0, but it should be updated on next refresh/detail fetch.
    // Requirement says: "For newly added manga, initialize the unread count to equal the total number of chapters available."
    // Since we might not have chapter list yet, we'll try to use existing local data if any.

    int totalChapters = 0;
    // Try to find if we have chapters locally
    final chapterCount = await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(manga.sourceId)
        .mangaIdEqualTo(manga.id)
        .count();

    if (chapterCount > 0) {
      totalChapters = chapterCount;
    }

    final entry = LocalLibraryEntry()
      ..mangaId = manga.id
      ..sourceId = manga.sourceId
      ..ownerUserId = _currentUserId
      ..title = manga.title
      ..thumbnailUrl = manga.thumbnailUrl
      ..author = manga.author
      ..language = manga.lang
      ..isBookmarked = true
      ..dateAddedAt = DateTime.now()
      ..unreadCount =
          totalChapters // Initialize with available count
      ..totalChapters = totalChapters;

    await isar.writeTxn(() async {
      await isar.collection<LocalLibraryEntry>().put(entry);
    });

    await syncManager.addToQueue('ADD_LIBRARY', {
      'mangaId': manga.id,
      'sourceId': manga.sourceId,
      'title': manga.title,
      'thumbnailUrl': manga.thumbnailUrl,
      'author': manga.author,
      'language': manga.lang,
    });

    if (categories != null && categories.isNotEmpty) {
      for (var catName in categories) {
        final cat = await isar
            .collection<LocalCategory>()
            .filter()
            .nameEqualTo(catName)
            .findFirst();
        if (cat != null) {
          await toggleCategoryAssignment(manga.id, manga.sourceId, cat.id);
        }
      }
    }
  }

  Future<void> toggleCategoryAssignment(
      String mangaId,
      String sourceId,
      int localCategoryId,
      ) async {
    final existing = await isar
        .collection<LocalCategoryAssignment>()
        .filter()
        .mangaIdEqualTo(mangaId)
        .sourceIdEqualTo(sourceId)
        .localCategoryIdEqualTo(localCategoryId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    final cat = await isar
        .collection<LocalCategory>()
        .filter()
        .idEqualTo(localCategoryId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    if (existing != null) {
      await isar.writeTxn(
            () => isar.collection<LocalCategoryAssignment>().delete(existing.id),
      );
      // Note: Backend API currently only supports "set", so "removal" would be
      // assigning to a different category or clearing.
    } else {
      final assignment = LocalCategoryAssignment()
        ..mangaId = mangaId
        ..sourceId = sourceId
        ..ownerUserId = _currentUserId
        ..scopedAssignmentKey = _assignmentScopedKey(
          mangaId,
          sourceId,
          localCategoryId,
          _currentUserId,
        )
        ..localCategoryId = localCategoryId;

      await isar.writeTxn(
            () => isar.collection<LocalCategoryAssignment>().put(assignment),
      );

      await syncManager.addToQueue('ASSIGN_CATEGORY', {
        'mangaId': mangaId,
        'localCategoryId': localCategoryId,
        'serverIdCategory': cat?.serverId,
      });
    }
  }

  Future<void> updateLibraryEntry(
      String token,
      String mangaId,
      Map<String, dynamic> updates,
      ) async {
    final entry = await isar
        .collection<LocalLibraryEntry>()
        .filter()
        .mangaIdEqualTo(mangaId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (entry != null) {
      if (updates.containsKey('isBookmarked'))
        entry.isBookmarked = updates['isBookmarked'];
      if (updates.containsKey('isUnread')) entry.isUnread = updates['isUnread'];
      if (updates.containsKey('isStarted'))
        entry.isStarted = updates['isStarted'];
      if (updates.containsKey('isCompleted'))
        entry.isCompleted = updates['isCompleted'];

      await isar.writeTxn(
            () => isar.collection<LocalLibraryEntry>().put(entry),
      );

      if (entry.serverId != null) {
        await syncManager.addToQueue('UPDATE_LIBRARY', {
          'id': entry.serverId,
          'updates': updates,
        });
      }
    }
  }

  Future<void> removeFromLibrary(
      String token,
      String mangaId,
      String sourceId,
      ) async {
    final entry = await isar
        .collection<LocalLibraryEntry>()
        .filter()
        .mangaIdEqualTo(mangaId)
        .sourceIdEqualTo(sourceId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    final serverId = entry?.serverId;

    await isar.writeTxn(() async {
      await isar
          .collection<LocalLibraryEntry>()
          .filter()
          .mangaIdEqualTo(mangaId)
          .sourceIdEqualTo(sourceId)
          .ownerUserIdEqualTo(_currentUserId)
          .deleteAll();

      await isar
          .collection<LocalCategoryAssignment>()
          .filter()
          .mangaIdEqualTo(mangaId)
          .sourceIdEqualTo(sourceId)
          .ownerUserIdEqualTo(_currentUserId)
          .deleteAll();
    });

    if (serverId != null) {
      await syncManager.addToQueue('REMOVE_LIBRARY', {'id': serverId});
    }
  }

  // --- Category methods ---

  Future<List<LocalCategory>> getCategories() async {
    return await isar
        .collection<LocalCategory>()
        .filter()
        .ownerUserIdEqualTo(_currentUserId)
        .findAll();
  }

  Future<void> createCategory(String name) async {
    // Generate a temporary local ID to satisfy unique index constraint until sync
    // Using timestamp + random component ensures uniqueness even if multiple are created quickly
    final tempServerId =
        'local_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';

    final category = LocalCategory()
      ..name = name
      ..ownerUserId = _currentUserId
      ..isSynced = false
      ..serverId = tempServerId;

    await isar.writeTxn(() async {
      await isar.collection<LocalCategory>().put(category);
    });

    // We pass the tempServerId so we can find it later if needed, though localId is primary
    await syncManager.addToQueue('CREATE_CATEGORY', {
      'name': name,
      'localId': category.id,
      'tempServerId': tempServerId,
    });
  }

  Future<void> updateCategory(int localId, String name) async {
    final category = await isar
        .collection<LocalCategory>()
        .filter()
        .idEqualTo(localId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (category != null) {
      category.name = name;
      category.isSynced = false;
      await isar.writeTxn(() => isar.collection<LocalCategory>().put(category));

      if (category.serverId != null) {
        await syncManager.addToQueue('UPDATE_CATEGORY', {
          'id': category.serverId,
          'name': name,
        });
      }
    }
  }

  Future<void> deleteCategory(int localId) async {
    final category = await isar
        .collection<LocalCategory>()
        .filter()
        .idEqualTo(localId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (category == null) return;

    final serverId = category.serverId;

    await isar.writeTxn(() async {
      await isar.collection<LocalCategory>().delete(localId);
      // Also delete any assignments for this category
      await isar
          .collection<LocalCategoryAssignment>()
          .filter()
          .localCategoryIdEqualTo(localId)
          .ownerUserIdEqualTo(_currentUserId)
          .deleteAll();
    });

    if (serverId != null) {
      await syncManager.addToQueue('DELETE_CATEGORY', {'id': serverId});
    }
  }
}
