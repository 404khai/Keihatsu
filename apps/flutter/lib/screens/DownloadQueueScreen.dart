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
  List<DownloadQueueItem> _resolveItems(List<DownloadQueueItem> source) {
    return source
        .where(
          (d) =>
              d.status == 0 || d.status == 1 || d.status == 3 || d.status == 4,
        )
        .toList();
  }

  void _toggleChapterPause(
    DownloadQueueItem chapter,
    DownloadProvider provider,
  ) {
    if (chapter.status == 1) {
      provider.pauseDownload(chapter.chapterId);
    } else if (chapter.status == 3 || chapter.status == 4) {
      provider.resumeDownload(chapter.chapterId);
    }
  }

  Future<bool> _confirmCancellation({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: Icon(
              Icons.cancel_outlined,
              color: Theme.of(dialogContext).colorScheme.error,
            ),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep downloading'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                child: const Text('Cancel download'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cancelManga(
    String sourceId,
    String mangaId,
    String mangaTitle,
    DownloadProvider provider,
  ) async {
    final confirmed = await _confirmCancellation(
      title: 'Cancel all downloads?',
      message: 'All queued chapters for $mangaTitle will be removed.',
    );
    if (!confirmed || !mounted) return;

    await provider.cancelMangaDownloads(sourceId, mangaId);
  }

  Future<void> _cancelChapter(
    DownloadQueueItem chapter,
    DownloadProvider provider,
  ) async {
    final confirmed = await _confirmCancellation(
      title: 'Cancel ${chapter.chapterName}?',
      message: 'Downloaded pages for this chapter will be removed.',
    );
    if (!confirmed || !mounted) return;

    await provider.removeFromQueue(chapter.chapterId);
  }

  Future<void> _handleQueueAction(
    DownloadQueueItem chapter,
    DownloadQueueItemAction action,
    DownloadProvider provider,
  ) async {
    switch (action) {
      case DownloadQueueItemAction.moveSeriesToTop:
        await provider.moveSeriesToTop(chapter.sourceId, chapter.mangaId);
        break;
      case DownloadQueueItemAction.moveSeriesToBottom:
        await provider.moveSeriesToBottom(chapter.sourceId, chapter.mangaId);
        break;
      case DownloadQueueItemAction.cancel:
        await _cancelChapter(chapter, provider);
        break;
      case DownloadQueueItemAction.cancelAllForSeries:
        await _cancelManga(
          chapter.sourceId,
          chapter.mangaId,
          chapter.mangaTitle,
          provider,
        );
        break;
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
                        Icons.cloud_download_outlined,
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
  ) {
    final String sourceId = items.first.sourceId;
    final String? image = extensionImageFor(sourceId);
    final List<DownloadQueueItem> sortedChapters = List.of(items)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final int chapterCount = items.length;

    return DownloadSection(
      label: _capitalizeExtensionName(extensionName),
      image: image,
      meta: '$chapterCount chapter${chapterCount == 1 ? '' : 's'}',
      child: DownloadExtensionChapterList(
        chapters: sortedChapters,
        onReorder: (oldIndex, newIndex) =>
            provider.reorderChaptersInExtension(sourceId, oldIndex, newIndex),
        onToggleChapterPause: (chapter) =>
            _toggleChapterPause(chapter, provider),
        onAction: (chapter, action) =>
            _handleQueueAction(chapter, action, provider),
      ),
    );
  }

  String _capitalizeExtensionName(String name) {
    if (name.isEmpty) return name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
