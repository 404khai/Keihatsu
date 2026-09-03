import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collection/collection.dart';
import '../models/local_models.dart';
import '../services/manga_repository.dart';

class DownloadProvider with ChangeNotifier {
  final Isar isar;
  final MangaRepository mangaRepo;
  final String? Function() getToken;

  List<DownloadQueueItem> _queue = [];
  final Map<String, String> _activeDownloads = {}; // sourceId -> chapterId
  final Map<String, bool> _cancellationTokens = {}; // chapterId -> isCancelled
  bool _isGlobalPaused = false;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;

  DownloadProvider({
    required this.isar,
    required this.mangaRepo,
    required this.getToken,
  }) {
    _init();
  }

  void _init() async {
    try {
      await mangaRepo.cleanupArchivedChapterDirectories();
    } catch (e) {
      print('Failed to clean legacy chapter image directories: $e');
    }

    // Load queue from DB
    _queue = await isar.downloadQueueItems.where().sortByPriority().findAll();

    // Check connectivity
    final result = await Connectivity().checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        result,
        ) {
      final wasOnline = _isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      if (_isOnline && !wasOnline && !_isGlobalPaused) {
        _processQueue();
      } else if (!_isOnline && wasOnline) {
        // Pause all active downloads implicitly by connectivity check in loop
        // But running downloads need to be cancelled/paused?
        // For now, let's assume the loop handles starting, and we might need to interrupt.
        // The repo doesn't support "pausing" a stream easily without cancellation.
        // We will implement pause as cancel-and-requeue-at-progress.
        _pauseAllDueToNetwork();
      }
      notifyListeners();
    });

    // Reset "Downloading" items to "Queued" or "Paused" on startup
    // because they are not actually running anymore.
    await isar.writeTxn(() async {
      for (var item in _queue) {
        if (item.status == 1) {
          // Downloading
          item.status = 0; // Queued
          await isar.downloadQueueItems.put(item);
        }
      }
    });

    // Refresh local queue
    _queue = await isar.downloadQueueItems.where().sortByPriority().findAll();
    notifyListeners();

    if (_isOnline && !_isGlobalPaused) {
      _processQueue();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  List<DownloadQueueItem> get queue => _queue;
  int get activeDownloadCount =>
      _queue.where((item) => item.status == 0 || item.status == 1).length;
  bool get isGlobalPaused => _isGlobalPaused;
  bool get isOnline => _isOnline;

  // --- Actions ---

  Future<void> addToQueue(
      String mangaId,
      String sourceId,
      String chapterId,
      String mangaTitle,
      String chapterName,
      double chapterNumber,
      String extensionName,
      String? mangaThumbnail,
      ) async {
    // Check if already exists
    final exists = await isar.downloadQueueItems
        .filter()
        .chapterIdEqualTo(chapterId)
        .findFirst();

    if (exists != null) return;

    // Find last priority
    final lastItem = await isar.downloadQueueItems
        .where()
        .sortByPriorityDesc()
        .findFirst();
    final newPriority = (lastItem?.priority ?? -1) + 1;

    final item = DownloadQueueItem()
      ..chapterId = chapterId
      ..mangaId = mangaId
      ..sourceId = sourceId
      ..chapterName = chapterName
      ..chapterNumber = chapterNumber
      ..mangaTitle = mangaTitle
      ..mangaThumbnail = mangaThumbnail
      ..extensionName = extensionName
      ..status =
      0 // Queued
      ..priority = newPriority
      ..dateAdded = DateTime.now();

    await isar.writeTxn(() async {
      await isar.downloadQueueItems.put(item);
    });

    _queue.add(item);
    notifyListeners();
    _processQueue();
  }

  Future<void> removeFromQueue(String chapterId) async {
    final item = _queue.firstWhereOrNull((i) => i.chapterId == chapterId);
    if (item == null) return;

    final isActive = _activeDownloads.containsValue(chapterId);
    _cancellationTokens[chapterId] = true;

    await isar.writeTxn(() async {
      await isar.downloadQueueItems.delete(item.id);
    });

    _queue.removeWhere((item) => item.chapterId == chapterId);
    notifyListeners();

    if (!isActive) {
      await mangaRepo.deleteDownloadedChapter(
        item.sourceId,
        item.mangaId,
        item.chapterId,
      );
      _cancellationTokens.remove(chapterId);
    }

    _processQueue();
  }

  Future<void> pauseDownload(String chapterId) async {
    final item = _queue.firstWhereOrNull((i) => i.chapterId == chapterId);
    if (item == null) return;

    if (item.status == 1) {
      // Is currently downloading
      _cancellationTokens[chapterId] = true;
    }

    item.status = 4; // Paused
    await isar.writeTxn(() async {
      await isar.downloadQueueItems.put(item);
    });

    notifyListeners();
    // processQueue will start next available if this one was running
    if (_activeDownloads.containsValue(chapterId)) {
      // It will be removed from active map when the download function exits
      // but we trigger processQueue to be safe or wait for it to exit
    }
  }

  Future<void> resumeDownload(String chapterId) async {
    final item = _queue.firstWhereOrNull((i) => i.chapterId == chapterId);
    if (item == null) return;

    item.status = 0; // Queued
    item.progress = 0;
    item.error = null;
    await isar.writeTxn(() async {
      await isar.downloadQueueItems.put(item);
    });

    notifyListeners();
    _processQueue();
  }

  Future<void> toggleGlobalPause() async {
    _isGlobalPaused = !_isGlobalPaused;

    if (_isGlobalPaused) {
      // Pause all active
      for (var sourceId in _activeDownloads.keys) {
        final chapterId = _activeDownloads[sourceId];
        if (chapterId != null) {
          _cancellationTokens[chapterId] = true;
          // We don't change their status to Paused in DB necessarily,
          // or maybe we should? The prompt says "pauses ... downloads".
          // If we just cancel but leave as "Queued" or "Downloading", they might restart.
          // Let's set a memory flag, but the UI needs to show paused.
          // Actually, let's iterate all queued/downloading items and set to Paused?
          // No, global pause is often a separate state overlay.
          // But for per-item control, let's just stop processing.
        }
      }
    } else {
      _processQueue();
    }
    notifyListeners();
  }

  void _pauseAllDueToNetwork() {
    for (var sourceId in _activeDownloads.keys) {
      final chapterId = _activeDownloads[sourceId];
      if (chapterId != null) {
        _cancellationTokens[chapterId] = true;
      }
    }
  }

  Future<void> reorderChaptersInExtension(
    String sourceId,
    int oldIndex,
    int newIndex,
  ) async {
    final List<DownloadQueueItem> extensionItems = _queue
        .where((i) => i.sourceId == sourceId)
        .sorted((a, b) => a.priority.compareTo(b.priority))
        .toList();

    if (oldIndex < 0 ||
        oldIndex >= extensionItems.length ||
        newIndex < 0 ||
        newIndex > extensionItems.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final DownloadQueueItem moved = extensionItems.removeAt(oldIndex);
    extensionItems.insert(newIndex, moved);

    final List<DownloadQueueItem> allSorted =
        _queue.sorted((a, b) => a.priority.compareTo(b.priority));
    final List<DownloadQueueItem> rebuilt = [];
    var extensionCursor = 0;

    for (final DownloadQueueItem item in allSorted) {
      if (item.sourceId == sourceId) {
        rebuilt.add(extensionItems[extensionCursor++]);
      } else {
        rebuilt.add(item);
      }
    }

    await _applyPriorityOrder(rebuilt);
  }

  Future<void> reorderInGlobalQueue(int oldIndex, int newIndex) async {
    final sorted = _queue.sorted((a, b) => a.priority.compareTo(b.priority));

    if (oldIndex < 0 ||
        oldIndex >= sorted.length ||
        newIndex < 0 ||
        newIndex > sorted.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);

    await _applyPriorityOrder(sorted);
  }

  Future<void> moveChapterToQueueFront(String chapterId) async {
    final sorted = _queue.sorted((a, b) => a.priority.compareTo(b.priority));
    final int index = sorted.indexWhere((i) => i.chapterId == chapterId);
    if (index <= 0) return;

    final item = sorted.removeAt(index);
    sorted.insert(0, item);
    await _applyPriorityOrder(sorted);
  }

  Future<void> _applyPriorityOrder(List<DownloadQueueItem> ordered) async {
    await isar.writeTxn(() async {
      for (var i = 0; i < ordered.length; i++) {
        ordered[i].priority = i;
        await isar.downloadQueueItems.put(ordered[i]);
      }
    });

    _queue = await isar.downloadQueueItems.where().sortByPriority().findAll();
    notifyListeners();
    _processQueue();
  }

  Future<void> reorderChaptersOfManga(
      String sourceId,
      String mangaId,
      int oldIndex,
      int newIndex,
      ) async {
    // 1. Get all chapters for this manga, sorted by priority
    final mangaChapters = _queue
        .where((i) => i.sourceId == sourceId && i.mangaId == mangaId)
        .sorted((a, b) => a.priority.compareTo(b.priority))
        .toList();

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = mangaChapters.removeAt(oldIndex);
    mangaChapters.insert(newIndex, item);

    // 2. Re-assign priorities based on the new order relative to the whole source list
    // This is tricky. Easier approach:
    // Get all items for the source.
    // Replace the block of this manga's chapters with the reordered list.
    // Re-assign priorities for the whole source.

    await _renormalizeSourcePriorities(
      sourceId,
      modifiedMangaId: mangaId,
      newMangaChapters: mangaChapters,
    );
  }

  Future<void> reorderMangasOfExtension(
      String sourceId,
      int oldIndex,
      int newIndex,
      ) async {
    // 1. Get unique mangaIds for this source, ordered by their *first* chapter's priority
    final sourceItems = _queue
        .where((i) => i.sourceId == sourceId)
        .sorted((a, b) => a.priority.compareTo(b.priority));

    final mangaIds = <String>[];
    final seen = <String>{};
    for (var item in sourceItems) {
      if (seen.add(item.mangaId)) {
        mangaIds.add(item.mangaId);
      }
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final movingMangaId = mangaIds.removeAt(oldIndex);
    mangaIds.insert(newIndex, movingMangaId);

    // 2. Reconstruct the list based on new manga order
    await _renormalizeSourcePriorities(sourceId, orderedMangaIds: mangaIds);
  }

  Future<void> _renormalizeSourcePriorities(
      String sourceId, {
        String? modifiedMangaId,
        List<DownloadQueueItem>? newMangaChapters,
        List<String>? orderedMangaIds,
      }) async {
    // Get all items for source
    final sourceItems = _queue
        .where((i) => i.sourceId == sourceId)
        .sorted((a, b) => a.priority.compareTo(b.priority));

    // If we are just reordering chapters within a manga
    if (modifiedMangaId != null && newMangaChapters != null) {
      // We need to keep the relative position of this manga block in the source list
      // But update the internal order of the block

      // Strategy:
      // 1. Extract all items of this manga
      // 2. Replace them with newMangaChapters
      // 3. Keep other items in place

      // Actually, since priority is just an int, we can just iterate through the sourceItems.
      // If item belongs to modifiedMangaId, pick next from newMangaChapters.

      final newSourceList = <DownloadQueueItem>[];
      int internalIndex = 0;

      for (var item in sourceItems) {
        if (item.mangaId == modifiedMangaId) {
          newSourceList.add(newMangaChapters[internalIndex++]);
        } else {
          newSourceList.add(item);
        }
      }

      // Save
      await isar.writeTxn(() async {
        for (var i = 0; i < newSourceList.length; i++) {
          newSourceList[i].priority = i;
          await isar.downloadQueueItems.put(newSourceList[i]);
        }
      });
    } else if (orderedMangaIds != null) {
      // We are reordering mangas
      // Rebuild the list: items of manga 1, then items of manga 2, etc.
      // But we must preserve chapter order within each manga!

      final newSourceList = <DownloadQueueItem>[];

      for (var mangaId in orderedMangaIds) {
        final mangaChapters = sourceItems
            .where((i) => i.mangaId == mangaId)
            .toList(); // They are already sorted by priority
        newSourceList.addAll(mangaChapters);
      }

      // Save
      await isar.writeTxn(() async {
        for (var i = 0; i < newSourceList.length; i++) {
          newSourceList[i].priority = i;
          await isar.downloadQueueItems.put(newSourceList[i]);
        }
      });
    }

    // Refresh local queue
    _queue = await isar.downloadQueueItems.where().sortByPriority().findAll();
    notifyListeners();
    _processQueue();
  }

  Future<void> cancelMangaDownloads(String sourceId, String mangaId) async {
    final items = _queue
        .where((i) => i.sourceId == sourceId && i.mangaId == mangaId)
        .toList();

    if (items.isEmpty) return;

    final activeChapterIds = _activeDownloads.values.toSet();

    // Active downloads stop after their current page request. Other queued
    // chapters can be cleaned up immediately.
    for (var item in items) {
      if (activeChapterIds.contains(item.chapterId)) {
        _cancellationTokens[item.chapterId] = true;
      }
    }

    // Remove from DB
    await isar.writeTxn(() async {
      for (var item in items) {
        await isar.downloadQueueItems.delete(item.id);
      }
    });

    // Update local state
    _queue.removeWhere((i) => i.sourceId == sourceId && i.mangaId == mangaId);
    notifyListeners();

    for (final item in items) {
      if (!activeChapterIds.contains(item.chapterId)) {
        await mangaRepo.deleteDownloadedChapter(
          item.sourceId,
          item.mangaId,
          item.chapterId,
        );
        _cancellationTokens.remove(item.chapterId);
      }
    }

    _processQueue();
  }

  Future<void> togglePauseManga(String sourceId, String mangaId) async {
    final items = _queue
        .where((i) => i.sourceId == sourceId && i.mangaId == mangaId)
        .toList();
    if (items.isEmpty) return;

    // Determine target state: if any is downloading/queued -> pause all. If all paused -> resume all.
    final anyActive = items.any((i) => i.status == 0 || i.status == 1);

    await isar.writeTxn(() async {
      for (var item in items) {
        if (anyActive) {
          if (item.status == 1) _cancellationTokens[item.chapterId] = true;
          item.status = 4; // Pause
        } else {
          if (item.status == 4) item.status = 0; // Resume
        }
        await isar.downloadQueueItems.put(item);
      }
    });

    // Refresh local queue
    _queue = await isar.downloadQueueItems.where().sortByPriority().findAll();
    notifyListeners();
    _processQueue();
  }

  // --- Processing ---

  Future<void> _processQueue() async {
    if (_isGlobalPaused || !_isOnline) return;

    // Group by source
    final bySource = groupBy(_queue, (DownloadQueueItem i) => i.sourceId);

    for (var sourceId in bySource.keys) {
      if (_activeDownloads.containsKey(sourceId)) {
        continue; // Already downloading for this source
      }

      // Get items for this source, sorted by priority
      final sourceItems = bySource[sourceId]!
        ..sort((a, b) => a.priority.compareTo(b.priority));

      // Find first queued item
      final nextItem = sourceItems.firstWhereOrNull(
            (i) => i.status == 0,
      ); // 0 = Queued

      if (nextItem != null) {
        _startDownload(nextItem);
      }
    }
  }

  Future<void> _startDownload(DownloadQueueItem item) async {
    final token = getToken();
    if (token == null)
      return; // Cannot download without token? Assuming required based on repo

    _activeDownloads[item.sourceId] = item.chapterId;
    _cancellationTokens[item.chapterId] = false;

    item.status = 1; // Downloading
    await isar.writeTxn(() async {
      await isar.downloadQueueItems.put(item);
    });
    notifyListeners();

    try {
      await mangaRepo.downloadChapter(
        token,
        item.sourceId,
        item.mangaId,
        item.chapterId,
        onProgress: (progress) {
          item.progress = progress;
          // Optimize: don't write to DB on every progress tick, just notify listeners
          // or throttle DB writes. For now, just memory update.
          notifyListeners();
        },
        isCancelled: () => _cancellationTokens[item.chapterId] ?? false,
      );

      if (_cancellationTokens[item.chapterId] == true) {
        throw Exception('Download cancelled');
      }

      if (item.progress < 1) {
        throw Exception('Download finished without completing every page');
      }

      // Success
      await isar.writeTxn(() async {
        // Remove from queue on success as requested
        await isar.downloadQueueItems.delete(item.id);
      });
      _queue.remove(item);
    } catch (e) {
      print("Download failed: $e");

      if (_cancellationTokens[item.chapterId] == true) {
        final wasRemoved = !_queue.any(
          (queuedItem) => queuedItem.id == item.id,
        );
        if (wasRemoved) {
          await mangaRepo.deleteDownloadedChapter(
            item.sourceId,
            item.mangaId,
            item.chapterId,
          );
        }

        // Was cancelled/paused manually
        // If paused, status is already 4. If cancelled, it's removed.
        // If we just cancelled for network/priority, set back to queued?
        if (!wasRemoved && item.status == 1) {
          // Still marked downloading
          item.status = 0; // Back to queued
          await isar.writeTxn(() => isar.downloadQueueItems.put(item));
        }
      } else {
        // Actual failure
        item.status = 3; // Failed
        item.error = e.toString();
        await isar.writeTxn(() => isar.downloadQueueItems.put(item));
      }
    } finally {
      _activeDownloads.remove(item.sourceId);
      _cancellationTokens.remove(item.chapterId);
      notifyListeners();
      // Trigger next
      _processQueue();
    }
  }

  Future<void> deleteChapters(List<LocalChapter> chapters) async {
    for (var chapter in chapters) {
      await mangaRepo.deleteDownloadedChapter(
        chapter.sourceId,
        chapter.mangaId,
        chapter.chapterId,
      );
    }
    notifyListeners();
  }
}
