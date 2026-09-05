import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';

import '../models/local_models.dart';
import 'library_api.dart';

class HistoryRepository {
  final Isar isar;
  final LibraryApi api;
  final String Function() getCurrentUserId;

  HistoryRepository({
    required this.isar,
    required this.api,
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

  Future<void> refreshHistoryFromServer(String token) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    const pageSize = 100;
    var page = 1;

    while (true) {
      final response = await api.getHistory(token, page: page, limit: pageSize);
      if (response.statusCode != 200) {
        throw Exception('Failed to refresh history');
      }

      final List<dynamic> entries = json.decode(response.body);
      if (entries.isEmpty) {
        break;
      }

      await _upsertHistoryEntries(entries);

      if (entries.length < pageSize) {
        break;
      }

      page++;
    }
  }

  Future<void> _upsertHistoryEntries(List<dynamic> entries) async {
    final ownerUserId = _currentUserId;

    await isar.writeTxn(() async {
      for (final rawEntry in entries) {
        final entry = rawEntry as Map<String, dynamic>;
        final mangaId = entry['mangaId'] as String;
        final sourceId = entry['sourceId'] as String;
        final chapterId = entry['chapterId'] as String;
        final title = (entry['title'] as String?)?.trim();
        final author = (entry['author'] as String?)?.trim();
        final thumbnailUrl = entry['thumbnailUrl'] as String?;
        final lastReadAt = entry['lastReadAt'] != null
            ? DateTime.parse(entry['lastReadAt'])
            : null;

        final localManga =
            await isar
                .collection<LocalManga>()
                .filter()
                .mangaIdEqualTo(mangaId)
                .sourceIdEqualTo(sourceId)
                .ownerUserIdEqualTo(ownerUserId)
                .findFirst() ??
                LocalManga()
                  ..mangaId = mangaId
                  ..sourceId = sourceId
                  ..ownerUserId = ownerUserId
                  ..title = title?.isNotEmpty == true ? title! : mangaId;

        localManga.ownerUserId = ownerUserId;
        if (title != null && title.isNotEmpty) {
          localManga.title = title;
        }
        if (author != null && author.isNotEmpty) {
          localManga.author = author;
        }
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
          localManga.thumbnailUrl = thumbnailUrl;
        }
        localManga.lastReadAt = lastReadAt;
        await isar.collection<LocalManga>().put(localManga);

        final localChapter =
            await isar
                .collection<LocalChapter>()
                .filter()
                .chapterIdEqualTo(chapterId)
                .mangaIdEqualTo(mangaId)
                .sourceIdEqualTo(sourceId)
                .ownerUserIdEqualTo(ownerUserId)
                .findFirst() ??
                LocalChapter()
                  ..chapterId = chapterId
                  ..mangaId = mangaId
                  ..sourceId = sourceId
                  ..ownerUserId = ownerUserId
                  ..scopedChapterKey = _chapterScopedKey(
                    chapterId,
                    mangaId,
                    sourceId,
                    ownerUserId,
                  )
                  ..name = (entry['chapterName'] as String?)?.trim().isNotEmpty ==
                      true
                      ? (entry['chapterName'] as String).trim()
                      : 'Chapter'
                  ..chapterNumber = (entry['chapterNumber'] as num?)?.toDouble() ?? 0
                  ..dateUpload = 0;

        localChapter.ownerUserId = ownerUserId;
        localChapter.scopedChapterKey = _chapterScopedKey(
          chapterId,
          mangaId,
          sourceId,
          ownerUserId,
        );
        if ((entry['chapterName'] as String?)?.trim().isNotEmpty == true) {
          localChapter.name = (entry['chapterName'] as String).trim();
        }
        if (entry['chapterNumber'] != null) {
          localChapter.chapterNumber =
              (entry['chapterNumber'] as num).toDouble();
        }
        localChapter.lastReadAt = lastReadAt;
        localChapter.lastPageRead = entry['pageNumber'] ?? 0;
        localChapter.isBookmarked = entry['isBookmarked'] ?? false;
        localChapter.isRead = entry['isRead'] ?? false;
        await isar.collection<LocalChapter>().put(localChapter);
      }
    });
  }
}
