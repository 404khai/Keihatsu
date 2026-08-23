import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/components/downloads/download_manga_group.dart';
import 'package:keihatsu/components/downloads/download_section.dart';
import 'package:keihatsu/components/menu/bottom_padding.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/data/mock_download_queue.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:keihatsu/providers/download_provider.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class DownloadQueueScreen extends StatefulWidget {
  const DownloadQueueScreen({super.key});

  @override
  State<DownloadQueueScreen> createState() => _DownloadQueueScreenState();
}

class _DownloadQueueScreenState extends State<DownloadQueueScreen> {
  List<DownloadQueueItem>? _mockItems;

  List<DownloadQueueItem> _resolveItems(List<DownloadQueueItem> source) {
    return source
        .where((d) => d.status == 0 || d.status == 1 || d.status == 4)
        .toList();

    /*
    _mockItems ??= mockDownloadQueue.map((download) {
      if (download.status != 1) return download;

      return DownloadQueueItem()
        ..chapterId = download.chapterId
        ..mangaId = download.mangaId
        ..sourceId = download.sourceId
        ..chapterName = download.chapterName
        ..chapterNumber = download.chapterNumber
        ..mangaTitle = download.mangaTitle
        ..mangaThumbnail = download.mangaThumbnail
        ..extensionName = download.extensionName
        ..status = 1
        ..progress = _fakeDownload.value
        ..priority = download.priority;
    }).toList();

    if (_mockItems != null) {
      for (final item in _mockItems!) {
        if (item.status == 1) {
          item.progress = _fakeDownload.value;
        }
      }
    }

    return List<DownloadQueueItem>.from(_mockItems!);
    */
  }

  void _reorderMangas(
    String sourceId,
    int oldIndex,
    int newIndex,
    DownloadProvider? provider,
    bool usingMock,
  ) {
    if (usingMock) {
      final List<DownloadQueueItem> sourceItems = (_mockItems ?? [])
          .where((item) => item.sourceId == sourceId)
          .sorted((a, b) => a.priority.compareTo(b.priority))
          .toList();

      final List<String> mangaIds = [];
      final Set<String> seen = {};
      for (final item in sourceItems) {
        if (seen.add(item.mangaId)) mangaIds.add(item.mangaId);
      }

      if (oldIndex < newIndex) newIndex -= 1;
      final String moved = mangaIds.removeAt(oldIndex);
      mangaIds.insert(newIndex, moved);

      final List<DownloadQueueItem> rebuilt = [];
      for (final mangaId in mangaIds) {
        rebuilt.addAll(sourceItems.where((item) => item.mangaId == mangaId));
      }

      final List<DownloadQueueItem> allSorted = (_mockItems ?? []).sorted(
        (a, b) => a.priority.compareTo(b.priority),
      );
      final List<DownloadQueueItem> finalList = [];
      var rebuiltCursor = 0;

      for (final item in allSorted) {
        if (item.sourceId == sourceId) {
          finalList.add(rebuilt[rebuiltCursor++]);
        } else {
          finalList.add(item);
        }
      }

      for (var i = 0; i < finalList.length; i++) {
        finalList[i].priority = i;
      }

      setState(() => _mockItems = finalList);
      return;
    }

    provider?.reorderMangasOfExtension(sourceId, oldIndex, newIndex);
  }

  void _reorderChaptersOfManga(
    String sourceId,
    String mangaId,
    int oldIndex,
    int newIndex,
    DownloadProvider? provider,
    bool usingMock,
  ) {
    if (usingMock) {
      final List<DownloadQueueItem> mangaChapters = (_mockItems ?? [])
          .where((item) => item.sourceId == sourceId && item.mangaId == mangaId)
          .sorted((a, b) => a.priority.compareTo(b.priority))
          .toList();

      if (oldIndex < newIndex) newIndex -= 1;
      final DownloadQueueItem moved = mangaChapters.removeAt(oldIndex);
      mangaChapters.insert(newIndex, moved);

      final List<DownloadQueueItem> allSorted = (_mockItems ?? []).sorted(
        (a, b) => a.priority.compareTo(b.priority),
      );
      final List<DownloadQueueItem> rebuilt = [];
      var chapterCursor = 0;

      for (final item in allSorted) {
        if (item.sourceId == sourceId && item.mangaId == mangaId) {
          rebuilt.add(mangaChapters[chapterCursor++]);
        } else {
          rebuilt.add(item);
        }
      }

      for (var i = 0; i < rebuilt.length; i++) {
        rebuilt[i].priority = i;
      }

      setState(() => _mockItems = rebuilt);
      return;
    }

    provider?.reorderChaptersOfManga(sourceId, mangaId, oldIndex, newIndex);
  }

  void _toggleChapterPause(
    DownloadQueueItem chapter,
    DownloadProvider provider,
    bool usingMock,
  ) {
    if (usingMock) {
      setState(() {
        if (chapter.status == 1) {
          chapter.status = 4;
        } else if (chapter.status == 4) {
          chapter.status = 0;
        }
      });
      return;
    }

    if (chapter.status == 1) {
      provider.pauseDownload(chapter.chapterId);
    } else if (chapter.status == 4) {
      provider.resumeDownload(chapter.chapterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color backgroundColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surface;
    final Color appBarColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surfaceContainer;
    final Color textColor = cs.onSurface;

    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final List<DownloadQueueItem> items = _resolveItems(provider.queue);
        const bool usingMock = false;

        final groupedByExtension = groupBy(
          items,
          (DownloadQueueItem i) => i.extensionName,
        );

        final sortedExtensions = groupedByExtension.keys.toList()..sort();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: const CustomBackButton(),
            title: Text(
              'Download Queue',
              style: GoogleFonts.unbounded(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: textColor,
                fontSize: 24,
              ),
            ),
            actions: [
              if (!usingMock)
                IconButton(
                  icon: Icon(
                    provider.isGlobalPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: textColor,
                  ),
                  onPressed: provider.toggleGlobalPause,
                  tooltip: provider.isGlobalPaused ? 'Resume All' : 'Pause All',
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_for_offline_outlined,
                        size: 64,
                        color: cs.primary,
                      ),
                      16.gap,
                      Text(
                        'No active downloads',
                        style: tt.titleMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      6.gap,
                      Text(
                        'Queued chapters will appear here.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    BottomPadding.of(context),
                  ),
                  children: [
                    for (int i = 0; i < sortedExtensions.length; i++) ...[
                      if (i > 0) 32.gap,
                      _buildExtensionSection(
                        sortedExtensions[i],
                        groupedByExtension[sortedExtensions[i]]!,
                        provider,
                        usingMock,
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildExtensionSection(
    String extensionName,
    List<DownloadQueueItem> items,
    DownloadProvider provider,
    bool usingMock,
  ) {
    final String sourceId = items.first.sourceId;
    final String? image = extensionImageFor(sourceId);

    final Map<String, List<DownloadQueueItem>> groupedByManga = groupBy(
      items,
      (DownloadQueueItem i) => i.mangaId,
    );
    final List<String> sortedMangaIds = groupedByManga.keys.toList()
      ..sort((a, b) {
        final int priorityA = groupedByManga[a]!
            .map((i) => i.priority)
            .reduce(math.min);
        final int priorityB = groupedByManga[b]!
            .map((i) => i.priority)
            .reduce(math.min);
        return priorityA.compareTo(priorityB);
      });

    final List<DownloadMangaGroupData> mangaGroups = [
      for (final mangaId in sortedMangaIds)
        DownloadMangaGroupData(
          mangaId: mangaId,
          mangaTitle: groupedByManga[mangaId]!.first.mangaTitle,
          mangaThumbnail: groupedByManga[mangaId]!.first.mangaThumbnail,
          chapters: List<DownloadQueueItem>.from(groupedByManga[mangaId]!)
            ..sort((a, b) => a.priority.compareTo(b.priority)),
        ),
    ];

    final int chapterCount = items.length;

    return DownloadSection(
      label: _capitalizeExtensionName(extensionName),
      image: image,
      meta: '$chapterCount chapter${chapterCount == 1 ? '' : 's'}',
      child: DownloadExtensionMangaList(
        mangaGroups: mangaGroups,
        onReorderManga: (oldIndex, newIndex) =>
            _reorderMangas(sourceId, oldIndex, newIndex, provider, usingMock),
        onReorderChapters: (mangaId, oldIndex, newIndex) =>
            _reorderChaptersOfManga(
              sourceId,
              mangaId,
              oldIndex,
              newIndex,
              provider,
              usingMock,
            ),
        onToggleChapterPause: (chapter) =>
            _toggleChapterPause(chapter, provider, usingMock),
      ),
    );
  }

  String _capitalizeExtensionName(String name) {
    if (name.isEmpty) return name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
