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

class _DownloadQueueScreenState extends State<DownloadQueueScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fakeDownload = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addListener(() => setState(() {}))
    ..repeat();

  List<DownloadQueueItem>? _mockItems;

  @override
  void dispose() {
    _fakeDownload.dispose();
    super.dispose();
  }

  List<DownloadQueueItem> _resolveItems(List<DownloadQueueItem> source) {
    if (source.isNotEmpty) {
      return source
          .where((d) => d.status == 0 || d.status == 1 || d.status == 4)
          .toList();
    }

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
  }

  void _reorderExtensionChapters(
    String sourceId,
    List<DownloadQueueItem> extensionItems,
    int oldIndex,
    int newIndex,
    DownloadProvider? provider,
    bool usingMock,
  ) {
    if (usingMock) {
      final List<DownloadQueueItem> extensionChapters = (_mockItems ?? [])
          .where((item) => item.sourceId == sourceId)
          .sorted((a, b) => a.priority.compareTo(b.priority))
          .toList();

      if (oldIndex < newIndex) newIndex -= 1;
      final DownloadQueueItem moved = extensionChapters.removeAt(oldIndex);
      extensionChapters.insert(newIndex, moved);

      final List<DownloadQueueItem> allSorted = (_mockItems ?? [])
          .sorted((a, b) => a.priority.compareTo(b.priority));
      final List<DownloadQueueItem> rebuilt = [];
      var extensionCursor = 0;

      for (final item in allSorted) {
        if (item.sourceId == sourceId) {
          rebuilt.add(extensionChapters[extensionCursor++]);
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

    provider?.reorderChaptersInExtension(sourceId, oldIndex, newIndex);
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
        final bool usingMock = provider.queue.isEmpty;

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
                  tooltip:
                      provider.isGlobalPaused ? 'Resume All' : 'Pause All',
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Text(
                    'No active downloads',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
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
                    if (usingMock) ...[
                      24.gap,
                      Center(
                        child: Text(
                          'Preview data — start a download to see your queue',
                          textAlign: TextAlign.center,
                          style: tt.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
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
    final List<DownloadQueueItem> sortedChapters =
        List<DownloadQueueItem>.from(items)
          ..sort((a, b) => a.priority.compareTo(b.priority));
    final int chapterCount = sortedChapters.length;

    return DownloadSection(
      label: extensionName,
      image: image,
      meta: '$chapterCount chapter${chapterCount == 1 ? '' : 's'}',
      child: DownloadExtensionChapterList(
        chapters: sortedChapters,
        onReorder: (oldIndex, newIndex) => _reorderExtensionChapters(
          sourceId,
          sortedChapters,
          oldIndex,
          newIndex,
          provider,
          usingMock,
        ),
      ),
    );
  }
}
