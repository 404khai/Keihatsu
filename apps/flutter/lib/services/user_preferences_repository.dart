import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_models.dart';
import '../models/user_preferences.dart';
import 'library_api.dart';
import 'sync_manager.dart';

class UserPreferencesRepository {
  final Isar isar;
  final LibraryApi api;
  final SyncManager syncManager;
  final String Function() getCurrentUserId;

  UserPreferencesRepository({
    required this.isar,
    required this.api,
    required this.syncManager,
    required this.getCurrentUserId,
  });

  String get _currentUserId => getCurrentUserId();

  Future<UserPreferences> getPreferences({
    bool forceRefresh = false,
    String? token,
  }) async {
    if (forceRefresh && token != null) {
      await refreshPreferences(token);
    }

    final local = await isar
        .collection<LocalUserPreferences>()
        .filter()
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (local == null) return UserPreferences();

    final Map<String, dynamic> sourcePrefsJson =
        local.sourcePreferencesJson.isNotEmpty
        ? json.decode(local.sourcePreferencesJson)
        : {};

    final Map<String, SourcePreference> sourcePrefs = sourcePrefsJson.map(
      (k, v) => MapEntry(k, SourcePreference.fromJson(v)),
    );

    return UserPreferences(
      libraryDisplayStyle: local.libraryDisplayStyle,
      libraryItemsPerRow: local.libraryItemsPerRow,
      overlayShowDownloaded: local.overlayShowDownloaded,
      overlayShowUnread: local.overlayShowUnread,
      overlayShowLanguage: local.overlayShowLanguage,
      tabsShowCategories: local.tabsShowCategories,
      tabsShowItemCount: local.tabsShowItemCount,
      categoriesDisplayMode: local.categoriesDisplayMode,
      sourcePreferences: sourcePrefs,
    );
  }

  Future<void> refreshPreferences(String token) async {
    final owner = _currentUserId;
    try {
      final pending = await isar
          .collection<SyncOperation>()
          .filter()
          .ownerUserIdEqualTo(owner)
          .completedEqualTo(false)
          .typeEqualTo('UPDATE_PREFERENCES')
          .count();
      if (pending > 0) return;
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      final response = await api.getPreferences(token);
      if (_currentUserId != owner) return;
      final pendingAfterFetch = await isar
          .collection<SyncOperation>()
          .filter()
          .ownerUserIdEqualTo(owner)
          .completedEqualTo(false)
          .typeEqualTo('UPDATE_PREFERENCES')
          .count();
      if (pendingAfterFetch > 0) return;
      if (response.statusCode == 200) {
        final prefs = UserPreferences.fromJson(json.decode(response.body));
        await _saveLocally(prefs, ownerUserId: owner);
      }
    } catch (e) {
      print('Error refreshing preferences: $e');
    }
  }

  Future<void> updatePreferences(UserPreferences partialUpdate) async {
    final owner = _currentUserId;
    // Save locally first
    await _saveLocally(partialUpdate, ownerUserId: owner);

    // Prepare payload for merge update (only changed fields could be sent,
    // but here we send what's in the partialUpdate object)
    final Map<String, dynamic> updateMap = partialUpdate.toJson();

    await syncManager.addToQueue(
      'UPDATE_PREFERENCES',
      updateMap,
      ownerUserId: owner,
    );
  }

  Future<void> _saveLocally(
    UserPreferences prefs, {
    String? ownerUserId,
  }) async {
    final owner = ownerUserId ?? _currentUserId;
    final local =
        await isar
                  .collection<LocalUserPreferences>()
                  .filter()
                  .ownerUserIdEqualTo(owner)
                  .findFirst() ??
              LocalUserPreferences()
          ..ownerUserId = owner;

    local.ownerUserId = owner;
    local.libraryDisplayStyle = prefs.libraryDisplayStyle;
    local.libraryItemsPerRow = prefs.libraryItemsPerRow;
    local.overlayShowDownloaded = prefs.overlayShowDownloaded;
    local.overlayShowUnread = prefs.overlayShowUnread;
    local.overlayShowLanguage = prefs.overlayShowLanguage;
    local.tabsShowCategories = prefs.tabsShowCategories;
    local.tabsShowItemCount = prefs.tabsShowItemCount;
    local.categoriesDisplayMode = prefs.categoriesDisplayMode;
    local.sourcePreferencesJson = json.encode(
      prefs.sourcePreferences.map((k, v) => MapEntry(k, v.toJson())),
    );

    await isar.writeTxn(
      () => isar.collection<LocalUserPreferences>().put(local),
    );
  }
}
