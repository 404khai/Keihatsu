import 'package:flutter/foundation.dart';

import '../models/local_models.dart';
import '../services/manga_repository.dart';
import 'offline_library_provider.dart';

enum LibraryUpdatesFilter { all, unread, downloaded }

@immutable
class LibraryUpdateItem {
  const LibraryUpdateItem({required this.libraryEntry, required this.chapter});

  final LocalLibraryEntry libraryEntry;
  final LocalChapter chapter;

  DateTime get uploadedAt =>
      DateTime.fromMillisecondsSinceEpoch(chapter.dateUpload);
}

@immutable
class LibraryUpdateGroup {
  const LibraryUpdateGroup({required this.date, required this.items});

  final DateTime date;
  final List<LibraryUpdateItem> items;
}

/// Aggregates the existing local-first library and chapter stores for the
/// Updates feed. Refreshing asks every library source for its latest chapters;
/// failed sources keep their cached chapters in the result.
class LibraryUpdatesProvider with ChangeNotifier {
  LibraryUpdatesProvider({required this.mangaRepository});

  final MangaRepository mangaRepository;

  List<LibraryUpdateItem> _items = const [];
  bool _isLoading = false;
  Object? _error;
  DateTime? _lastUpdatedAt;
  LibraryUpdatesFilter _filter = LibraryUpdatesFilter.all;

  List<LibraryUpdateItem> get items => _items;
  bool get isLoading => _isLoading;
  Object? get error => _error;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  LibraryUpdatesFilter get filter => _filter;

  List<LibraryUpdateGroup> get groups {
    final visible = _items.where((item) {
      return switch (_filter) {
        LibraryUpdatesFilter.all => true,
        LibraryUpdatesFilter.unread => !item.chapter.isRead,
        LibraryUpdatesFilter.downloaded => item.chapter.downloaded,
      };
    });
    final grouped = <DateTime, List<LibraryUpdateItem>>{};
    for (final item in visible) {
      final value = item.uploadedAt;
      final day = DateTime(value.year, value.month, value.day);
      grouped.putIfAbsent(day, () => []).add(item);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return days
        .map(
          (day) => LibraryUpdateGroup(
            date: day,
            items: grouped[day]!
              ..sort(
                (a, b) =>
                    b.chapter.chapterNumber.compareTo(a.chapter.chapterNumber),
              ),
          ),
        )
        .toList(growable: false);
  }

  void setFilter(LibraryUpdatesFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  Future<void> refresh(OfflineLibraryProvider library) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await library.refresh(true);
      final entries = List<LocalLibraryEntry>.from(library.library);
      final results = await Future.wait(
        entries.map((entry) async {
          final chapters = await mangaRepository.getChapters(
            entry.sourceId,
            entry.mangaId,
          );
          return chapters
              .where((chapter) => chapter.dateUpload > 0)
              .map(
                (chapter) =>
                    LibraryUpdateItem(libraryEntry: entry, chapter: chapter),
              );
        }),
      );
      _items = results.expand((items) => items).toList(growable: false)
        ..sort((a, b) => b.chapter.dateUpload.compareTo(a.chapter.dateUpload));
      _lastUpdatedAt = DateTime.now();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sources do not expose a release-calendar endpoint yet. A title's most
  /// common recent upload weekday is used as its local schedule prediction.
  List<LocalLibraryEntry> scheduledEntriesFor(DateTime date) {
    final byManga = <String, List<LibraryUpdateItem>>{};
    for (final item in _items) {
      final key = '${item.libraryEntry.sourceId}::${item.libraryEntry.mangaId}';
      byManga.putIfAbsent(key, () => []).add(item);
    }

    final releases = <LocalLibraryEntry>[];
    for (final values in byManga.values) {
      final weekdayCounts = <int, int>{};
      for (final item in values.take(12)) {
        weekdayCounts.update(
          item.uploadedAt.weekday,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (weekdayCounts.isEmpty) continue;
      final predictedWeekday = weekdayCounts.entries.reduce((a, b) {
        if (a.value != b.value) return a.value > b.value ? a : b;
        return a.key == values.first.uploadedAt.weekday ? a : b;
      }).key;
      if (date.weekday == predictedWeekday) {
        releases.add(values.first.libraryEntry);
      }
    }
    releases.sort((a, b) => a.title.compareTo(b.title));
    return releases;
  }
}
