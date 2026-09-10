import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import '../models/local_models.dart';
import 'library_api.dart';
import 'operation_id.dart';

class SyncManager {
  final Isar isar;
  final LibraryApi libraryApi;
  final String? Function() getToken;
  final String Function() getCurrentUserId;

  Timer? _syncTimer;
  bool _isProcessing = false;

  SyncManager({
    required this.isar,
    required this.libraryApi,
    required this.getToken,
    required this.getCurrentUserId,
  }) {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        processSyncQueue();
      }
    });

    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => processSyncQueue(),
    );
  }

  void dispose() {
    _syncTimer?.cancel();
  }

  Future<void> addToQueue(String type, Map<String, dynamic> payload) async {
    final queuedPayload = Map<String, dynamic>.from(payload);
    if (type == 'UPDATE_HISTORY') {
      queuedPayload.putIfAbsent('operationId', createOperationId);
    }

    final op = SyncOperation()
      ..type = type
      ..payload = json.encode(queuedPayload)
      ..timestamp = DateTime.now()
      ..ownerUserId = getCurrentUserId()
      ..completed = false;

    await isar.writeTxn(() async {
      await isar.collection<SyncOperation>().put(op);
    });

    processSyncQueue();
  }

  Future<int> recoverUnsyncedLibraryEntries({
    required String ownerUserId,
  }) async {
    final localEntries = await isar
        .collection<LocalLibraryEntry>()
        .filter()
        .ownerUserIdEqualTo(ownerUserId)
        .findAll();
    final unsyncedEntries = localEntries
        .where((entry) => entry.serverId?.trim().isEmpty ?? true)
        .toList();
    if (unsyncedEntries.isEmpty) return 0;

    final existingOperations = await isar
        .collection<SyncOperation>()
        .filter()
        .ownerUserIdEqualTo(ownerUserId)
        .completedEqualTo(false)
        .findAll();
    final queuedByManga = <String, SyncOperation>{};
    for (final operation in existingOperations) {
      if (operation.type != 'ADD_LIBRARY') continue;
      try {
        final payload = json.decode(operation.payload) as Map<String, dynamic>;
        queuedByManga['${payload['sourceId']}::${payload['mangaId']}'] =
            operation;
      } catch (_) {
        // A malformed legacy operation cannot safely suppress recovery.
      }
    }

    final operationsToSave = <SyncOperation>[];
    for (final entry in unsyncedEntries) {
      final key = '${entry.sourceId}::${entry.mangaId}';
      final existing = queuedByManga[key];
      if (existing != null) {
        if (existing.retryCount >= 5) {
          existing
            ..retryCount = 0
            ..errorMessage = null;
          operationsToSave.add(existing);
        }
        continue;
      }

      operationsToSave.add(
        SyncOperation()
          ..type = 'ADD_LIBRARY'
          ..payload = json.encode({
            'mangaId': entry.mangaId,
            'sourceId': entry.sourceId,
            'title': entry.title,
            'thumbnailUrl': entry.thumbnailUrl,
            'author': entry.author,
            'language': entry.language,
          })
          ..timestamp = entry.dateAddedAt ?? DateTime.now()
          ..ownerUserId = ownerUserId
          ..completed = false,
      );
    }

    if (operationsToSave.isNotEmpty) {
      await isar.writeTxn(
        () => isar.collection<SyncOperation>().putAll(operationsToSave),
      );
      debugPrint(
        '[SyncManager] Recovered ${operationsToSave.length} unsynced library operations',
      );
    }
    await processSyncQueue(ownerUserId: ownerUserId);
    return operationsToSave.length;
  }

  Future<void> processSyncQueue({String? ownerUserId}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final scopedUserId = ownerUserId ?? getCurrentUserId();
      final token = getToken();
      if (token == null) {
        debugPrint('[SyncManager] No token available, skipping sync');
        return;
      }
      debugPrint('[SyncManager] Processing sync queue with token...');

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final pendingOps = await isar
          .collection<SyncOperation>()
          .filter()
          .ownerUserIdEqualTo(scopedUserId)
          .completedEqualTo(false)
          .sortByTimestamp()
          .findAll();

      for (final op in pendingOps) {
        // Skip operations that have exceeded max retries
        if (op.retryCount >= 5) {
          continue;
        }

        debugPrint(
          '[SyncManager] Executing: ${op.type} (retry: ${op.retryCount})',
        );
        bool success = await _executeOperation(op, token, scopedUserId);
        if (success) {
          debugPrint('[SyncManager] ✅ ${op.type} succeeded');
          op.completed = true;
          await isar.writeTxn(() => isar.collection<SyncOperation>().put(op));
        } else {
          // Only break for dependency-sensitive operations
          // ASSIGN_CATEGORY depends on ADD_LIBRARY and CREATE_CATEGORY
          // For other operations, just skip and continue
          if (op.type == 'ADD_LIBRARY' || op.type == 'CREATE_CATEGORY') {
            // These may have dependent ASSIGN_CATEGORY ops, so stop processing
            break;
          }
          // For independent operations, continue processing
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _executeOperation(
    SyncOperation op,
    String token,
    String ownerUserId,
  ) async {
    final Map<String, dynamic> payload = json.decode(op.payload);

    try {
      switch (op.type) {
        case 'ADD_LIBRARY':
          final response = await libraryApi.addMangaToLibrary(token, payload);
          debugPrint(
            '[SyncManager] ADD_LIBRARY response: ${response.statusCode} ${response.body}',
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = json.decode(response.body);
            final String serverId = data['id'];

            await isar.writeTxn(() async {
              final entry = await isar
                  .collection<LocalLibraryEntry>()
                  .filter()
                  .mangaIdEqualTo(payload['mangaId'])
                  .sourceIdEqualTo(payload['sourceId'])
                  .ownerUserIdEqualTo(ownerUserId)
                  .findFirst();
              if (entry != null) {
                entry.serverId = serverId;
                await isar.collection<LocalLibraryEntry>().put(entry);
              }
            });
            return true;
          }
          // Handle 409 Conflict (already exists in DB) — treat as success
          if (response.statusCode == 409) {
            // Try to get the existing entry from server to update the local serverId
            try {
              final data = json.decode(response.body);
              final String? serverId = data['id'];
              if (serverId != null) {
                await isar.writeTxn(() async {
                  final entry = await isar
                      .collection<LocalLibraryEntry>()
                      .filter()
                      .mangaIdEqualTo(payload['mangaId'])
                      .sourceIdEqualTo(payload['sourceId'])
                      .ownerUserIdEqualTo(ownerUserId)
                      .findFirst();
                  if (entry != null) {
                    entry.serverId = serverId;
                    await isar.collection<LocalLibraryEntry>().put(entry);
                  }
                });
              }
            } catch (_) {}
            return true;
          }
          break;

        case 'CREATE_CATEGORY':
          final response = await libraryApi.createCategory(
            token,
            payload['name'],
          );
          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 409) {
            final data = json.decode(response.body);
            final String? serverId = data['id'];

            await isar.writeTxn(() async {
              final cat = await isar
                  .collection<LocalCategory>()
                  .filter()
                  .idEqualTo(payload['localId'])
                  .ownerUserIdEqualTo(ownerUserId)
                  .findFirst();
              if (cat != null) {
                if (serverId != null) cat.serverId = serverId;
                cat.isSynced = true;
                await isar.collection<LocalCategory>().put(cat);
              }
            });
            return true;
          }
          break;

        case 'ASSIGN_CATEGORY':
          final String mangaId = payload['mangaId'];
          final String sourceId = payload['sourceId'];
          final int localCategoryId = payload['localCategoryId'];

          // Resolve Category serverId if it was local-only when queued
          final cat = await isar
              .collection<LocalCategory>()
              .filter()
              .idEqualTo(localCategoryId)
              .ownerUserIdEqualTo(ownerUserId)
              .findFirst();
          final String? serverCategoryId = cat?.serverId;

          // Ensure Manga is synced to server library first
          final entry = await isar
              .collection<LocalLibraryEntry>()
              .filter()
              .mangaIdEqualTo(mangaId)
              .sourceIdEqualTo(sourceId)
              .ownerUserIdEqualTo(ownerUserId)
              .findFirst();

          if (serverCategoryId == null || entry?.serverId == null) {
            // Dependency not met yet (ADD_LIBRARY or CREATE_CATEGORY hasn't finished)
            return false;
          }

          final response = await libraryApi.assignMangaToCategory(
            token,
            mangaId,
            serverCategoryId,
          );
          return response.statusCode == 200 || response.statusCode == 201;

        case 'REMOVE_LIBRARY':
          final response = await libraryApi.deleteLibraryEntry(
            token,
            payload['id'],
          );
          return response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 404;

        case 'UPDATE_LIBRARY':
          final response = await libraryApi.updateLibraryEntry(
            token,
            payload['id'],
            payload['updates'],
          );
          return response.statusCode == 200 || response.statusCode == 204;

        case 'DELETE_CATEGORY':
          final response = await libraryApi.deleteCategory(
            token,
            payload['id'],
          );
          return response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 404;

        case 'UPDATE_PREFERENCES':
          final response = await libraryApi.updatePreferences(token, payload);
          return response.statusCode == 200 || response.statusCode == 204;

        case 'UPDATE_HISTORY':
          var operationId = payload['operationId'] as String?;
          if (operationId == null) {
            // Upgrade operations queued by older app builds in-place so every
            // retry keeps the same idempotency key.
            operationId = createOperationId();
            payload['operationId'] = operationId;
            op.payload = json.encode(payload);
            await isar.writeTxn(() => isar.collection<SyncOperation>().put(op));
          }
          final response = await libraryApi.syncHistory(
            token: token,
            operationId: operationId,
            mangaId: payload['mangaId'],
            sourceId: payload['sourceId'],
            chapterId: payload['chapterId'],
            pageNumber: payload['pageNumber'],
            lastReadAt: DateTime.parse(payload['lastReadAt']),
            title: payload['title'],
            thumbnailUrl: payload['thumbnailUrl'],
            author: payload['author'],
            chapterName: payload['chapterName'],
            chapterNumber: (payload['chapterNumber'] as num?)?.toDouble(),
            isBookmarked: payload['isBookmarked'],
            isRead: payload['isRead'],
            readingTimeMs: payload['readingTimeMs'],
          );
          return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      // Log error and increment retry count
      op.errorMessage = e.toString();
      op.retryCount++;
      await isar.writeTxn(() async {
        await isar.collection<SyncOperation>().put(op);
      });
    }
    return false;
  }
}
