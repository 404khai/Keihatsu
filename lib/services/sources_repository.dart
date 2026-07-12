import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import '../models/local_models.dart';
import '../models/source.dart';
import 'sources_api.dart';
import 'file_service.dart';
import 'dart:convert';

class SourcesRepository {
  final Isar isar;
  final SourcesApi api;
  final FileService fileService;

  SourcesRepository({
    required this.isar,
    required this.api,
    required this.fileService,
  });

  static const List<Map<String, String>> _bundledSources = [
    {
      'sourceId': 'mangafire',
      'name': 'MangaFire',
      'lang': 'en',
      'baseUrl': 'https://mangafire.to',
    },
    {
      'sourceId': 'weebcentral',
      'name': 'WeebCentral',
      'lang': 'en',
      'baseUrl': 'https://weebcentral.com',
    },
    {
      'sourceId': 'batcave',
      'name': 'BatCave',
      'lang': 'en',
      'baseUrl': 'https://batcave.net',
    },
    {
      'sourceId': 'atsumaru',
      'name': 'Atsumaru',
      'lang': 'en',
      'baseUrl': 'https://atsumaru.com',
    },
    {
      'sourceId': 'manhuatop',
      'name': 'ManhuaTop',
      'lang': 'en',
      'baseUrl': 'https://manhuatop.org',
    },
  ];

  Future<List<LocalSource>> getSources({bool forceRefresh = false}) async {
    final connectivity = await Connectivity().checkConnectivity();
    final bool isOnline = connectivity != ConnectivityResult.none;

    if (isOnline && forceRefresh) {
      await refreshSources();
    }

    var localSources =
        await isar.localSources.where().sortByPinnedDesc().thenByName().findAll();

    if (localSources.isEmpty && isOnline) {
      await refreshSources();
      localSources =
          await isar.localSources.where().sortByPinnedDesc().thenByName().findAll();
    }

    if (localSources.isEmpty) {
      await _seedBundledSources();
      localSources =
          await isar.localSources.where().sortByPinnedDesc().thenByName().findAll();
    }

    return localSources;
  }

  Future<void> _seedBundledSources() async {
    await isar.writeTxn(() async {
      for (final bundled in _bundledSources) {
        final existing = await isar.localSources
            .filter()
            .sourceIdEqualTo(bundled['sourceId']!)
            .findFirst();

        if (existing != null) continue;

        final source = LocalSource()
          ..sourceId = bundled['sourceId']!
          ..name = bundled['name']!
          ..lang = bundled['lang']!
          ..baseUrl = bundled['baseUrl']!
          ..enabled = bundled['sourceId'] == 'manhuatop'
          ..lastUpdatedAt = DateTime.now();

        await isar.localSources.put(source);
      }
    });
  }

  Future<void> refreshSources() async {
    try {
      final remoteSources = await api.getSources();

      await isar.writeTxn(() async {
        for (var remote in remoteSources) {
          final existing = await isar.localSources.filter().sourceIdEqualTo(remote.id).findFirst();

          final local = (existing ?? LocalSource())
            ..sourceId = remote.id
            ..name = remote.name
            ..lang = remote.lang
            ..baseUrl = remote.baseUrl
            ..iconUrl = remote.iconUrl
            ..versionId = remote.versionId
            ..lastUpdatedAt = DateTime.now();

          await isar.localSources.put(local);

          // Download icon if not exists or URL changed
          if (remote.iconUrl != null && (existing?.iconUrl != remote.iconUrl || existing?.iconLocalPath == null)) {
            final localPath = await fileService.downloadFile(
              remote.iconUrl!,
              'icons/${remote.id}.png'
            );
            if (localPath != null) {
              local.iconLocalPath = localPath;
              await isar.localSources.put(local);
            }
          }
        }
      });
    } catch (e) {
      print('Failed to refresh sources: $e');
    }
  }

  Future<void> toggleSource(String sourceId, bool enabled) async {
    final source = await isar.localSources.filter().sourceIdEqualTo(sourceId).findFirst();
    if (source != null) {
      source.enabled = enabled;
      await isar.writeTxn(() => isar.localSources.put(source));
      // In a real app, you'd also queue a sync operation for user preferences here
    }
  }

  Future<void> pinSource(String sourceId, bool pinned) async {
    final source = await isar.localSources.filter().sourceIdEqualTo(sourceId).findFirst();
    if (source != null) {
      source.pinned = pinned;
      await isar.writeTxn(() => isar.localSources.put(source));
    }
  }
}
