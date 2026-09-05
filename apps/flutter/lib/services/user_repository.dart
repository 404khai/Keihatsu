import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/local_models.dart';
import '../models/user_preferences.dart';
import 'auth_api.dart';
import 'file_service.dart';

class UserRepository {
  final Isar isar;
  final AuthApi api;
  final FileService fileService;
  final String Function() getCurrentUserId;

  UserRepository({
    required this.isar,
    required this.api,
    required this.fileService,
    required this.getCurrentUserId,
  });

  String get _currentUserId => getCurrentUserId();

  Future<UserPreferences?> getPreferences() async {
    final local = await isar
        .collection<LocalUserPreferences>()
        .filter()
        .ownerUserIdEqualTo(_currentUserId)
        .findFirst();
    if (local == null) return null;

    final Map<String, dynamic> sourcePrefsJson = local.sourcePreferencesJson.isNotEmpty
        ? json.decode(local.sourcePreferencesJson)
        : {};

    final Map<String, SourcePreference> sourcePrefs = sourcePrefsJson.map(
            (k, v) => MapEntry(k, SourcePreference.fromJson(v))
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
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    try {
      final prefsData = await api.getPreferences(token);
      await savePreferencesLocally(prefsData);
    } catch (e) {
      print('Error refreshing preferences: $e');
    }
  }

  Future<void> savePreferencesLocally(UserPreferences prefsData) async {
    final localPrefs =
        await isar
            .collection<LocalUserPreferences>()
            .filter()
            .ownerUserIdEqualTo(_currentUserId)
            .findFirst() ??
            LocalUserPreferences()
              ..ownerUserId = _currentUserId;

    localPrefs.ownerUserId = _currentUserId;
    localPrefs.libraryDisplayStyle = prefsData.libraryDisplayStyle;
    localPrefs.categoriesDisplayMode = prefsData.categoriesDisplayMode;
    localPrefs.libraryItemsPerRow = prefsData.libraryItemsPerRow;
    localPrefs.overlayShowDownloaded = prefsData.overlayShowDownloaded;
    localPrefs.overlayShowUnread = prefsData.overlayShowUnread;
    localPrefs.overlayShowLanguage = prefsData.overlayShowLanguage;
    localPrefs.tabsShowCategories = prefsData.tabsShowCategories;
    localPrefs.tabsShowItemCount = prefsData.tabsShowItemCount;
    localPrefs.sourcePreferencesJson = json.encode(
        prefsData.sourcePreferences.map((k, v) => MapEntry(k, v.toJson()))
    );

    await isar.writeTxn(() => isar.collection<LocalUserPreferences>().put(localPrefs));
  }

  Future<void> updatePreferences(String token, Map<String, dynamic> updates) async {
    try {
      final updatedPrefs = await api.updatePreferences(token, updates);
      await savePreferencesLocally(updatedPrefs);
    } catch (e) {
      print('Error updating preferences: $e');
      rethrow;
    }
  }

  Future<void> updateSourcePreference(String token, String sourceId, {bool? enabled, bool? pinned}) async {
    final prefs = await getPreferences();
    if (prefs == null) return;

    final current = prefs.sourcePreferences[sourceId];
    final currentEnabled = current?.enabled ?? true;
    final currentPinned = current?.pinned ?? false;

    final newSourcePref = {
      'enabled': enabled ?? currentEnabled,
      'pinned': pinned ?? currentPinned,
    };

    await updatePreferences(token, {
      'source_preferences': {
        sourceId: newSourcePref
      }
    });
  }

  Future<String?> getCachedAvatar(String? remoteUrl) async {
    if (remoteUrl == null) return null;
    final fileName = remoteUrl.split('/').last;
    final localPath = 'profile/avatar_$fileName';

    final file = await fileService.downloadFile(remoteUrl, localPath);
    return file;
  }
}
