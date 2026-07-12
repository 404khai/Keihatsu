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

    return mockDownloadQueue.map((download) {
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
    final Color textColor = isDarkTheme ? Colors.white : Colors.black87;

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
  ) {
    final String sourceId = items.first.sourceId;
    final String? image = extensionImageFor(sourceId);

    final groupedByManga = groupBy(items, (DownloadQueueItem i) => i.mangaId);
    final sortedMangaIds = groupedByManga.keys.toList()
      ..sort((a, b) {
        final priorityA = groupedByManga[a]!.map((i) => i.priority).min;
        final priorityB = groupedByManga[b]!.map((i) => i.priority).min;
        return priorityA.compareTo(priorityB);
      });

    final int chapterCount = items.length;

    return DownloadSection(
      label: extensionName,
      image: image,
      meta: '$chapterCount chapter${chapterCount == 1 ? '' : 's'}',
      children: [
        for (final mangaId in sortedMangaIds)
          DownloadMangaGroup(
            key: ValueKey(mangaId),
            mangaTitle: groupedByManga[mangaId]!.first.mangaTitle,
            mangaThumbnail: groupedByManga[mangaId]!.first.mangaThumbnail,
            chapters: groupedByManga[mangaId]!
              ..sort((a, b) => a.priority.compareTo(b.priority)),
          ),
      ],
    );
  }
}
