import 'package:flutter/material.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/components/downloads/download_section.dart';
import 'package:keihatsu/components/downloads/download_tile.dart';
import 'package:keihatsu/components/menu/bottom_padding.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/styled_sheet.dart';
import 'package:keihatsu/data/mock_download_queue.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:keihatsu/providers/download_provider.dart';
import 'package:provider/provider.dart';

class DownloadQueueScreen extends StatefulWidget {
  const DownloadQueueScreen({super.key});

  @override
  State<DownloadQueueScreen> createState() => _DownloadQueueScreenState();
}

class _DownloadQueueScreenState extends State<DownloadQueueScreen>
    with SingleTickerProviderStateMixin {
  int _fakeCompleted = 0;
  final Set<String> _deleted = {};
  final Set<String> _removing = {};

  late final AnimationController _fakeDownload = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )
    ..addListener(() => setState(() {}))
    ..addStatusListener(_onFakeDownloadDone)
    ..forward();

  void _onFakeDownloadDone(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    final int queueLength =
        mockDownloadQueue.where((d) => d.status != 2).length;

    setState(() => _fakeCompleted++);
    if (_fakeCompleted < queueLength) {
      _fakeDownload
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fakeDownload.dispose();
    super.dispose();
  }

  void _startRemoving(Iterable<String> chapterIds) {
    setState(() => _removing.addAll(chapterIds));
  }

  void _finishRemoving(String chapterId) {
    setState(() {
      _removing.remove(chapterId);
      _deleted.add(chapterId);
    });
  }

  List<DownloadQueueItem> _resolveItems(List<DownloadQueueItem> source) {
    if (source.isNotEmpty) return source;

    final List<DownloadQueueItem> downloadQueue = mockDownloadQueue
        .where((d) => d.status != 2 && !_deleted.contains(d.chapterId))
        .toList();

    final List<DownloadQueueItem> queue = [];
    final List<DownloadQueueItem> onDevice = [];

    for (int i = 0; i < downloadQueue.length; i++) {
      final DownloadQueueItem download = downloadQueue[i];

      if (i < _fakeCompleted) {
        onDevice.add(
          DownloadQueueItem()
            ..chapterId = download.chapterId
            ..mangaId = download.mangaId
            ..sourceId = download.sourceId
            ..chapterName = download.chapterName
            ..chapterNumber = download.chapterNumber
            ..mangaTitle = download.mangaTitle
            ..mangaThumbnail = download.mangaThumbnail
            ..extensionName = download.extensionName
            ..status = 2
            ..priority = download.priority,
        );
      } else if (i == _fakeCompleted) {
        queue.add(
          DownloadQueueItem()
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
            ..priority = download.priority,
        );
      } else {
        queue.add(
          DownloadQueueItem()
            ..chapterId = download.chapterId
            ..mangaId = download.mangaId
            ..sourceId = download.sourceId
            ..chapterName = download.chapterName
            ..chapterNumber = download.chapterNumber
            ..mangaTitle = download.mangaTitle
            ..mangaThumbnail = download.mangaThumbnail
            ..extensionName = download.extensionName
            ..status = 0
            ..priority = download.priority,
        );
      }
    }

    for (final DownloadQueueItem download in mockDownloadQueue) {
      if (download.status != 2) continue;
      if (_deleted.contains(download.chapterId)) continue;
      onDevice.add(download);
    }

    return [...queue, ...onDevice];
  }

  Future<void> _deleteOne(BuildContext context, DownloadQueueItem item) async {
    final String size = sizeLabelMb(40 + item.chapterNumber * 8);

    final bool confirmed = await StyledSheet.show(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Remove download?',
      message:
          'Removes "${item.mangaTitle} · ${item.chapterName}" from this device '
          'and frees $size. You can download it again anytime.',
      confirmLabel: 'Free up $size',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      _startRemoving([item.chapterId]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$size freed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final List<DownloadQueueItem> allItems =
            _resolveItems(provider.queue);
        final bool usingMock = provider.queue.isEmpty;

        final List<DownloadQueueItem> queue = allItems
            .where((d) => d.status == 0 || d.status == 1)
            .toList();
        final List<DownloadQueueItem> onDevice =
            allItems.where((d) => d.status == 2).toList();

        final int onDeviceMb = onDevice.fold(
          0,
          (sum, d) => sum + (40 + d.chapterNumber * 8).round(),
        );

        DownloadTile tile(DownloadQueueItem item) {
          return DownloadTile(
            key: ValueKey(item.chapterId),
            item: item,
            onDelete: item.status == 2
                ? () => _deleteOne(context, item)
                : null,
            removing: _removing.contains(item.chapterId),
            onRemoved: () => _finishRemoving(item.chapterId),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: const CustomBackButton(),
            title: const Text('Download Queue'),
            actions: [
              if (!usingMock)
                IconButton(
                  icon: Icon(
                    provider.isGlobalPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  onPressed: provider.toggleGlobalPause,
                  tooltip:
                      provider.isGlobalPaused ? 'Resume All' : 'Pause All',
                ),
            ],
          ),
          body: allItems.isEmpty
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
                    if (queue.isNotEmpty) ...[
                      DownloadSection(
                        label: 'Downloading',
                        children: [for (final item in queue) tile(item)],
                      ),
                      32.gap,
                    ],
                    DownloadSection(
                      label: 'On device',
                      meta: sizeLabelMb(onDeviceMb.toDouble()),
                      children: [for (final item in onDevice) tile(item)],
                    ),
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
}
