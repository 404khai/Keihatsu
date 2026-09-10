import 'package:flutter/foundation.dart';

import 'history_repository.dart';
import 'library_repository.dart';

class SessionBootstrapService {
  final LibraryRepository libraryRepository;
  final HistoryRepository historyRepository;

  String? _activeUserId;
  Future<void>? _inFlight;

  SessionBootstrapService({
    required this.libraryRepository,
    required this.historyRepository,
  });

  Future<void> bootstrapUserData({
    required String token,
    required String userId,
    bool force = false,
  }) {
    if (!force && _activeUserId == userId && _inFlight != null) {
      return _inFlight!;
    }

    _activeUserId = userId;
    _inFlight = _runBootstrap(token, userId);
    return _inFlight!;
  }

  Future<void> _runBootstrap(String token, String userId) async {
    try {
      await _attempt(
        'categories',
        () => libraryRepository.refreshCategories(
          token: token,
          ownerUserId: userId,
          reconcileSnapshot: true,
        ),
      );
      await _attempt('unsynced library entries', () async {
        await libraryRepository.recoverUnsyncedEntries(ownerUserId: userId);
      });
      await _attempt(
        'library',
        () => libraryRepository.refreshLibrary(
          token: token,
          ownerUserId: userId,
          reconcileSnapshot: true,
        ),
      );
      await _attempt(
        'history',
        () => historyRepository.refreshHistoryFromServer(
          token,
          ownerUserId: userId,
        ),
      );
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _attempt(
    String resource,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      debugPrint('Failed to bootstrap $resource: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
