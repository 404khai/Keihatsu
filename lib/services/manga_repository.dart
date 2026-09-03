import 'dart:io';

import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_models.dart';
import '../models/manga.dart';
import 'sources_api.dart';
import 'file_service.dart';
import 'library_api.dart';
import 'sync_manager.dart';

class MangaRepository {
  final Isar isar;
  final SourcesApi api;
  final FileService fileService;
  final LibraryApi libraryApi;
  final SyncManager? syncManager; // Optional, can be injected
  final String Function() getCurrentUserId;

  MangaRepository({
    required this.isar,
    required this.api,
    required this.fileService,
    required this.libraryApi,
    this.syncManager,
    required this.getCurrentUserId,
  });

  String get _currentUserId => getCurrentUserId();

  String _chapterScopedKey(
    String chapterId,
    String mangaId,
    String sourceId,
    String ownerUserId,
  ) {
    return '$ownerUserId::$sourceId::$mangaId::$chapterId';
  }

  Future<void> updateReadingProgress({
    required LocalManga manga,
    required String chapterId,
    required int pageIndex,
    String? token, // Auth token for syncing
    bool? isRead,
    int? readingTimeMs,
  }) async {
    final now = DateTime.now();

    // 1. Update LocalManga
    manga.ownerUserId = _currentUserId;
    manga.lastReadAt = now;
    await isar.writeTxn(() async {
      await isar.collection<LocalManga>().put(manga);
    });

    // 2. Update LocalChapter
    final chapter = await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(manga.sourceId)
        .mangaIdEqualTo(manga.mangaId)
        .chapterIdEqualTo(chapterId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    if (chapter != null) {
      chapter.scopedChapterKey = _chapterScopedKey(
        chapter.chapterId,
        chapter.mangaId,
        chapter.sourceId,
        _currentUserId,
      );
      chapter.lastReadAt = now;
      chapter.lastPageRead = pageIndex;
      if (isRead != null) chapter.isRead = isRead;
      await isar.writeTxn(() async {
        await isar.collection<LocalChapter>().put(chapter);
      });
    } else {
      // If chapter doesn't exist locally (streaming), create a skeleton
      final newChapter = LocalChapter()
        ..chapterId = chapterId
        ..mangaId = manga.mangaId
        ..sourceId = manga.sourceId
        ..ownerUserId = _currentUserId
        ..scopedChapterKey = _chapterScopedKey(
          chapterId,
          manga.mangaId,
          manga.sourceId,
          _currentUserId,
        )
        ..name =
            "Chapter" // Placeholder, should be updated when chapter details are fetched
        ..chapterNumber =
            0 // Placeholder
        ..dateUpload = now.millisecondsSinceEpoch
        ..lastReadAt = now
        ..lastPageRead = pageIndex
        ..isRead = isRead ?? false;

      await isar.writeTxn(() async {
        await isar.collection<LocalChapter>().put(newChapter);
      });
    }

    // 3. Update LocalLibraryEntry (if exists)
    final libraryEntry = await isar
        .collection<LocalLibraryEntry>()
        .filter()
        .mangaIdEqualTo(manga.mangaId)
        .sourceIdEqualTo(manga.sourceId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    if (libraryEntry != null) {
      if (isRead != null) {
        if (isRead) {
          if (libraryEntry.unreadCount > 0) libraryEntry.unreadCount -= 1;
        } else {
          libraryEntry.unreadCount += 1;
        }
      }
      libraryEntry.lastReadAt = now;
      await isar.writeTxn(() async {
        await isar.collection<LocalLibraryEntry>().put(libraryEntry);
      });
    }

    // 4. Sync with Backend
    if (syncManager != null) {
      final chapterName = chapter?.name;
      final chapterNumber = chapter?.chapterNumber;
      final payload = {
        'mangaId': manga.mangaId,
        'sourceId': manga.sourceId,
        'chapterId': chapterId,
        'title': manga.title,
        if (manga.thumbnailUrl != null) 'thumbnailUrl': manga.thumbnailUrl,
        if (manga.author != null) 'author': manga.author,
        if (chapterName != null) 'chapterName': chapterName,
        if (chapterNumber != null) 'chapterNumber': chapterNumber,
        'pageNumber': pageIndex,
        'lastReadAt': now.toIso8601String(),
        if (isRead != null) 'isRead': isRead,
        if (readingTimeMs != null) 'readingTimeMs': readingTimeMs,
      };

      final connectivity = await Connectivity().checkConnectivity();
      if (token != null && !connectivity.contains(ConnectivityResult.none)) {
        try {
          await libraryApi.syncHistory(
            token: token,
            mangaId: manga.mangaId,
            sourceId: manga.sourceId,
            chapterId: chapterId,
            pageNumber: pageIndex,
            lastReadAt: now,
            title: manga.title,
            thumbnailUrl: manga.thumbnailUrl,
            author: manga.author,
            chapterName: chapterName,
            chapterNumber: chapterNumber,
            isRead: isRead,
            readingTimeMs: readingTimeMs,
          );
        } catch (e) {
          // If direct sync fails, queue it
          await syncManager!.addToQueue('UPDATE_HISTORY', payload);
        }
      } else {
        await syncManager!.addToQueue('UPDATE_HISTORY', payload);
      }
    }
  }

  Future<LocalManga?> getMangaDetails(String sourceId, String mangaId) async {
    final connectivity = await Connectivity().checkConnectivity();
    final bool isOnline = !connectivity.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final remote = await api.getMangaDetails(sourceId, mangaId);
        return await _cacheManga(remote);
      } catch (e) {
        print('Error fetching remote manga details: $e');
      }
    }

    return await isar
        .collection<LocalManga>()
        .filter()
        .sourceIdEqualTo(sourceId)
        .mangaIdEqualTo(mangaId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
  }

  Future<LocalManga> _cacheManga(Manga manga) async {
    final existing = await isar
        .collection<LocalManga>()
        .filter()
        .sourceIdEqualTo(manga.sourceId)
        .mangaIdEqualTo(manga.id)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();

    final local = (existing ?? LocalManga())
      ..mangaId = manga.id
      ..sourceId = manga.sourceId
      ..ownerUserId = _currentUserId
      ..title = manga.title
      ..description = manga.description
      ..thumbnailUrl = manga.thumbnailUrl
      ..author = manga.author
      ..artist = manga.artist
      ..status = manga.status
      ..genres = manga.genres;

    await isar.writeTxn(() async {
      await isar.collection<LocalManga>().put(local);
    });

    if (existing?.thumbnailUrl != manga.thumbnailUrl ||
        existing?.thumbnailLocalPath == null) {
      final localPath = await fileService.downloadFile(
        manga.thumbnailUrl,
        'thumbnails/${manga.sourceId}/${manga.id}.jpg',
        referer: manga.url,
      );
      if (localPath != null) {
        local.thumbnailLocalPath = localPath;
        await isar.writeTxn(() => isar.collection<LocalManga>().put(local));
      }
    }
    return local;
  }

  Future<List<LocalChapter>> getChapters(
    String sourceId,
    String mangaId,
  ) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.none)) {
      try {
        final remoteChapters = await api.getChapters(sourceId, mangaId);
        await isar.writeTxn(() async {
          for (var remote in remoteChapters) {
            final existing = await isar
                .collection<LocalChapter>()
                .filter()
                .sourceIdEqualTo(sourceId)
                .mangaIdEqualTo(mangaId)
                .chapterIdEqualTo(remote.id)
                .ownerUserIdEqualTo(_currentUserId)
                .findFirst();

            final local = (existing ?? LocalChapter())
              ..chapterId = remote.id
              ..mangaId = mangaId
              ..sourceId = sourceId
              ..ownerUserId = _currentUserId
              ..scopedChapterKey = _chapterScopedKey(
                remote.id,
                mangaId,
                sourceId,
                _currentUserId,
              )
              ..name = remote.name
              ..chapterNumber = remote.chapterNumber
              ..dateUpload = remote.dateUpload
              ..scanlator = remote.scanlator;

            await isar.collection<LocalChapter>().put(local);
          }
        });
      } catch (e) {
        print('Error fetching chapters: $e');
      }
    }

    return await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(sourceId)
        .mangaIdEqualTo(mangaId)
        .ownerUserIdEqualTo(_currentUserId)
        .sortByChapterNumberDesc()
        .findAll();
  }

  Future<void> downloadChapter(
    String token,
    String sourceId,
    String mangaId,
    String chapterId, {
    Function(double)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // 0. Request permission first
    final hasPermission = await fileService.requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    final pages = await api.getPages(sourceId, chapterId);

    // 1. Save page records
    await isar.writeTxn(() async {
      for (var page in pages) {
        final localPage = LocalPage()
          ..chapterId = chapterId
          ..index = page.index
          ..ownerUserId = _currentUserId
          ..imageRemoteUrl = page.imageUrl;
        await isar.collection<LocalPage>().put(localPage);
      }
    });

    // 2. Download images
    final downloadedPagePaths = <String>[];
    for (var i = 0; i < pages.length; i++) {
      if (isCancelled?.call() == true) {
        throw Exception('Download cancelled');
      }

      final page = pages[i];
      final downloadUrl = api.getDownloadImageUrl(
        sourceId: sourceId,
        imageUrl: page.imageUrl,
        referer: page.url,
      );
      final localPath = await fileService.downloadFile(
        downloadUrl,
        fileService.getChapterPageSubPath(
          sourceId: sourceId,
          mangaId: mangaId,
          chapterId: chapterId,
          index: page.index,
        ),
        referer: page.url,
      );

      if (localPath != null) {
        downloadedPagePaths.add(localPath);
        final lp = await isar
            .collection<LocalPage>()
            .filter()
            .chapterIdEqualTo(chapterId)
            .indexEqualTo(page.index)
            .ownerUserIdEqualTo(_currentUserId)
            .findFirst();
        if (lp != null) {
          lp.imageLocalPath = localPath;
          await isar.writeTxn(() => isar.collection<LocalPage>().put(lp));
        }
      } else {
        throw Exception('Failed to download page ${page.index + 1}');
      }

      onProgress?.call((i + 1) / pages.length);
    }

    if (isCancelled?.call() == true) {
      throw Exception('Download cancelled');
    }

    // Keep the individual page files available to the offline reader and also
    // write the portable archive users can find in the public downloads folder.
    final cbzPath = await fileService.createCbz(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
      pagePaths: downloadedPagePaths,
    );
    final cbzFile = File(cbzPath);
    if (!await cbzFile.exists() || await cbzFile.length() == 0) {
      throw Exception('The CBZ archive was not saved');
    }

    // 3. Mark as downloaded
    final chapter = await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(sourceId)
        .mangaIdEqualTo(mangaId)
        .chapterIdEqualTo(chapterId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (chapter != null) {
      chapter.scopedChapterKey = _chapterScopedKey(
        chapter.chapterId,
        chapter.mangaId,
        chapter.sourceId,
        _currentUserId,
      );
      chapter.downloaded = true;
      await isar.writeTxn(() => isar.collection<LocalChapter>().put(chapter));

      // Update LibraryEntry downloaded count
      final libraryEntry = await isar
          .collection<LocalLibraryEntry>()
          .filter()
          .mangaIdEqualTo(mangaId)
          .sourceIdEqualTo(sourceId)
          .ownerUserIdEqualTo(_currentUserId)
          .findFirst();

      if (libraryEntry != null) {
        libraryEntry.downloadedCount += 1;
        await isar.writeTxn(
          () => isar.collection<LocalLibraryEntry>().put(libraryEntry),
        );
      }
    }

    // 4. Notify server (optional but requested)
    try {
      await libraryApi.downloadChapter(
        token: token,
        sourceId: sourceId,
        mangaId: mangaId,
        chapterId: chapterId,
      );
    } catch (e) {
      print('Failed to notify server of download: $e');
    }
  }

  Future<List<LocalPage>> getChapterPages(String chapterId) async {
    return await isar
        .collection<LocalPage>()
        .filter()
        .chapterIdEqualTo(chapterId)
        .ownerUserIdEqualTo(_currentUserId)
        .sortByIndex()
        .findAll();
  }

  Future<void> toggleChapterBookmark(
    LocalChapter chapter,
    bool value, {
    String? token,
  }) async {
    chapter.scopedChapterKey = _chapterScopedKey(
      chapter.chapterId,
      chapter.mangaId,
      chapter.sourceId,
      _currentUserId,
    );
    chapter.isBookmarked = value;
    await isar.writeTxn(() async {
      await isar.collection<LocalChapter>().put(chapter);
    });

    if (syncManager != null) {
      final payload = {
        'mangaId': chapter.mangaId,
        'sourceId': chapter.sourceId,
        'chapterId': chapter.chapterId,
        'chapterName': chapter.name,
        'chapterNumber': chapter.chapterNumber,
        'pageNumber': chapter.lastPageRead ?? 0,
        'lastReadAt': DateTime.now().toIso8601String(),
        'isBookmarked': value,
      };

      final connectivity = await Connectivity().checkConnectivity();
      if (token != null && !connectivity.contains(ConnectivityResult.none)) {
        try {
          await libraryApi.syncHistory(
            token: token,
            mangaId: chapter.mangaId,
            sourceId: chapter.sourceId,
            chapterId: chapter.chapterId,
            pageNumber: chapter.lastPageRead ?? 0,
            lastReadAt: DateTime.now(),
            chapterName: chapter.name,
            chapterNumber: chapter.chapterNumber,
            isBookmarked: value,
          );
        } catch (e) {
          await syncManager!.addToQueue('UPDATE_HISTORY', payload);
        }
      } else {
        await syncManager!.addToQueue('UPDATE_HISTORY', payload);
      }
    }
  }

  Future<void> toggleChapterRead(
    LocalChapter chapter,
    bool value, {
    String? token,
  }) async {
    chapter.scopedChapterKey = _chapterScopedKey(
      chapter.chapterId,
      chapter.mangaId,
      chapter.sourceId,
      _currentUserId,
    );
    chapter.isRead = value;
    await isar.writeTxn(() async {
      await isar.collection<LocalChapter>().put(chapter);
    });

    if (syncManager != null) {
      final payload = {
        'mangaId': chapter.mangaId,
        'sourceId': chapter.sourceId,
        'chapterId': chapter.chapterId,
        'chapterName': chapter.name,
        'chapterNumber': chapter.chapterNumber,
        'pageNumber': chapter.lastPageRead ?? 0,
        'lastReadAt': DateTime.now().toIso8601String(),
        'isRead': value,
      };

      final connectivity = await Connectivity().checkConnectivity();
      if (token != null && !connectivity.contains(ConnectivityResult.none)) {
        try {
          await libraryApi.syncHistory(
            token: token,
            mangaId: chapter.mangaId,
            sourceId: chapter.sourceId,
            chapterId: chapter.chapterId,
            pageNumber: chapter.lastPageRead ?? 0,
            lastReadAt: DateTime.now(),
            chapterName: chapter.name,
            chapterNumber: chapter.chapterNumber,
            isRead: value,
          );
        } catch (e) {
          await syncManager!.addToQueue('UPDATE_HISTORY', payload);
        }
      } else {
        await syncManager!.addToQueue('UPDATE_HISTORY', payload);
      }
    }
  }

  Future<void> deleteDownloadedChapter(
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    final chapter = await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(sourceId)
        .mangaIdEqualTo(mangaId)
        .chapterIdEqualTo(chapterId)
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    final wasDownloaded = chapter?.downloaded ?? false;

    // 1. Delete files
    await fileService.deleteChapter(sourceId, mangaId, chapterId);

    // 2. Delete LocalPage entries
    await isar.writeTxn(() async {
      await isar
          .collection<LocalPage>()
          .filter()
          .chapterIdEqualTo(chapterId)
          .ownerUserIdEqualTo(_currentUserId)
          .deleteAll();
    });

    // 3. Update Isar
    if (chapter != null) {
      chapter.downloaded = false;
      await isar.writeTxn(() => isar.collection<LocalChapter>().put(chapter));

      // 3. Update LibraryEntry count
      final libraryEntry = await isar
          .collection<LocalLibraryEntry>()
          .filter()
          .mangaIdEqualTo(mangaId)
          .sourceIdEqualTo(sourceId)
          .ownerUserIdEqualTo(_currentUserId)
          .findFirst();

      if (libraryEntry != null && wasDownloaded) {
        if (libraryEntry.downloadedCount > 0) {
          libraryEntry.downloadedCount -= 1;
          await isar.writeTxn(
            () => isar.collection<LocalLibraryEntry>().put(libraryEntry),
          );
        }
      }
    }
  }
}
