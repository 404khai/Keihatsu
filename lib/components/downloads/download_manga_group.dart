import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keihatsu/common/shape_values.dart';
import 'package:keihatsu/components/downloads/download_tile.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:material_wavy_progress_indicator/material_wavy_progress_indicator.dart';

class DownloadMangaGroupData {
  const DownloadMangaGroupData({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaThumbnail,
    required this.chapters,
  });

  final String mangaId;
  final String mangaTitle;
  final String? mangaThumbnail;
  final List<DownloadQueueItem> chapters;
}

/// Collapsible manga groups within one extension. Drag a manga row to reorder
/// the whole group; drag sub-chapter handles to reorder within a manga.
class DownloadExtensionMangaList extends StatelessWidget {
  const DownloadExtensionMangaList({
    super.key,
    required this.mangaGroups,
    required this.onReorderManga,
    required this.onReorderChapters,
    this.onToggleChapterPause,
    this.borderRadius,
  });

  final List<DownloadMangaGroupData> mangaGroups;
  final void Function(int oldIndex, int newIndex) onReorderManga;
  final void Function(String mangaId, int oldIndex, int newIndex)
  onReorderChapters;
  final void Function(DownloadQueueItem chapter)? onToggleChapterPause;
  final BorderRadius? borderRadius;

  BorderRadius _radiusFor(int index) {
    const Radius outer = Radius.circular(MenuSection.outerRadius);
    const Radius inner = Radius.circular(MenuSection.innerRadius);

    if (mangaGroups.length == 1) {
      return borderRadius ?? BorderRadius.circular(MenuSection.outerRadius);
    }

    return BorderRadius.vertical(
      top: index == 0 ? outer : inner,
      bottom: index == mangaGroups.length - 1 ? outer : inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.circular(MenuSection.outerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: mangaGroups.length,
        onReorder: onReorderManga,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 6,
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final DownloadMangaGroupData group = mangaGroups[index];

          return Column(
            key: ValueKey(group.mangaId),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                Divider(
                  height: MenuSection.tileGap,
                  thickness: MenuSection.tileGap,
                  color: cs.surface,
                ),
              ReorderableDragStartListener(
                index: index,
                child: DownloadMangaGroup(
                  mangaTitle: group.mangaTitle,
                  mangaThumbnail: group.mangaThumbnail,
                  chapters: group.chapters,
                  borderRadius: _radiusFor(index),
                  onToggleChapterPause: onToggleChapterPause,
                  onReorderChapters: group.chapters.length > 1
                      ? (oldIndex, newIndex) =>
                            onReorderChapters(group.mangaId, oldIndex, newIndex)
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One manga in the download queue. Expands to show individual chapters when
/// there are multiple queued chapters.
class DownloadMangaGroup extends StatefulWidget {
  const DownloadMangaGroup({
    super.key,
    required this.mangaTitle,
    required this.mangaThumbnail,
    required this.chapters,
    this.borderRadius,
    this.initiallyExpanded = false,
    this.onReorderChapters,
    this.onToggleChapterPause,
  });

  final String mangaTitle;
  final String? mangaThumbnail;
  final List<DownloadQueueItem> chapters;
  final BorderRadius? borderRadius;
  final bool initiallyExpanded;
  final void Function(int oldIndex, int newIndex)? onReorderChapters;
  final void Function(DownloadQueueItem chapter)? onToggleChapterPause;

  @override
  State<DownloadMangaGroup> createState() => _DownloadMangaGroupState();
}

class _DownloadMangaGroupState extends State<DownloadMangaGroup> {
  late bool _expanded = widget.initiallyExpanded;
  late List<DownloadQueueItem> _chapters = List<DownloadQueueItem>.from(
    widget.chapters,
  );

  @override
  void didUpdateWidget(covariant DownloadMangaGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapters != widget.chapters) {
      _chapters = List<DownloadQueueItem>.from(widget.chapters);
    }
  }

  bool get _hasMultipleChapters => _chapters.length > 1;

  DownloadQueueItem get _primaryChapter {
    final downloading = _chapters.where((c) => c.status == 1);
    if (downloading.isNotEmpty) return downloading.first;
    return _chapters.first;
  }

  String _statusLabel() {
    final int downloading = _chapters.where((c) => c.status == 1).length;
    final int queued = _chapters.where((c) => c.status == 0).length;
    final int paused = _chapters.where((c) => c.status == 4).length;

    if (downloading > 0 && queued > 0) {
      return '$downloading downloading · $queued queued';
    }
    if (downloading > 0) {
      return '$downloading chapter${downloading == 1 ? '' : 's'} downloading';
    }
    if (queued > 0) return '$queued chapter${queued == 1 ? '' : 's'} queued';
    if (paused > 0) return 'Paused';
    return '${_chapters.length} chapter${_chapters.length == 1 ? '' : 's'}';
  }

  void _handleChapterReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _chapters.removeAt(oldIndex);
      _chapters.insert(newIndex, item);
    });
    widget.onReorderChapters?.call(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final DownloadQueueItem primary = _primaryChapter;
    final bool canReorderChapters =
        widget.onReorderChapters != null && _hasMultipleChapters;

    return Material(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius:
            widget.borderRadius ??
            BorderRadius.circular(MenuSection.innerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _hasMultipleChapters
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: MaterialShapeBorder(shape: ShapeValues.cover),
                    ),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: _CoverImage(path: widget.mangaThumbnail),
                    ),
                  ),
                  14.gap,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mangaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        4.gap,
                        Text(
                          _hasMultipleChapters
                              ? _statusLabel()
                              : primary.chapterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (!_hasMultipleChapters) ...[
                          4.gap,
                          Text(
                            sizeLabelMb(40 + primary.chapterNumber * 8),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_hasMultipleChapters)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                    )
                  else
                    _StatusIndicator(
                      item: primary,
                      onTogglePause: widget.onToggleChapterPause == null
                          ? null
                          : () => widget.onToggleChapterPause!(primary),
                    ),
                ],
              ),
            ),
          ),
          if (_hasMultipleChapters && _expanded) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            if (canReorderChapters)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _chapters.length,
                onReorder: _handleChapterReorder,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  return _NestedChapterRow(
                    key: ValueKey(_chapters[index].chapterId),
                    chapter: _chapters[index],
                    index: index,
                    isLast: index == _chapters.length - 1,
                    onTogglePause: widget.onToggleChapterPause == null
                        ? null
                        : () => widget.onToggleChapterPause!(_chapters[index]),
                  );
                },
              )
            else
              for (int i = 0; i < _chapters.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 12,
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                _NestedChapterRow(
                  chapter: _chapters[i],
                  index: i,
                  isLast: i == _chapters.length - 1,
                  enableDrag: false,
                  onTogglePause: widget.onToggleChapterPause == null
                      ? null
                      : () => widget.onToggleChapterPause!(_chapters[i]),
                ),
              ],
            8.gap,
          ],
        ],
      ),
    );
  }
}

class _NestedChapterRow extends StatelessWidget {
  const _NestedChapterRow({
    super.key,
    required this.chapter,
    required this.index,
    required this.isLast,
    this.enableDrag = true,
    this.onTogglePause,
  });

  final DownloadQueueItem chapter;
  final int index;
  final bool isLast;
  final bool enableDrag;
  final VoidCallback? onTogglePause;

  static const double _horizontalPadding = 12;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Widget dragHandle = Icon(
      Icons.drag_indicator_rounded,
      color: cs.onSurfaceVariant,
      size: 18,
    );

    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_horizontalPadding, 6, 16, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (enableDrag)
                ReorderableDragStartListener(index: index, child: dragHandle)
              else
                dragHandle,
              8.gap,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chapter.chapterName, style: tt.bodyMedium),
                  Text(
                    sizeLabelMb(40 + chapter.chapterNumber * 8),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _StatusIndicator(item: chapter, onTogglePause: onTogglePause),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: _horizontalPadding,
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.item, this.onTogglePause});

  final DownloadQueueItem item;
  final VoidCallback? onTogglePause;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool canToggle =
        onTogglePause != null && (item.status == 1 || item.status == 4);

    final Widget indicator = switch (item.status) {
      1 => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularWavyProgressIndicator(value: item.progress.clamp(0.0, 1.0)),
            Icon(Icons.stop_rounded, size: 20, color: cs.primary),
          ],
        ),
      ),
      4 => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularWavyProgressIndicator(value: item.progress.clamp(0.0, 1.0)),
            Icon(Icons.play_arrow_rounded, size: 24, color: cs.primary),
          ],
        ),
      ),
      0 => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const CircularWavyProgressIndicator(value: 0),
            Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
      3 => Icon(Icons.error_outline, color: cs.error, size: 28),
      _ => const SizedBox(width: 44, height: 44),
    };

    if (!canToggle) return indicator;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTogglePause,
        customBorder: const CircleBorder(),
        child: indicator,
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (path == null) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
      );
    }

    if (path!.startsWith('http')) {
      return Image.network(
        path!,
        fit: BoxFit.cover,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Android) AppleWebKit/537.36 Chrome/133 Safari/537.36',
          'Referer': Uri.tryParse(path!)?.origin ?? '',
        },
        errorBuilder: (context, error, stack) => ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
        ),
      );
    }

    if (path!.startsWith('/') || path!.startsWith('file:')) {
      return Image.file(
        File(path!.startsWith('file:') ? Uri.parse(path!).toFilePath() : path!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
        ),
      );
    }

    return Image.asset(
      path!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
      ),
    );
  }
}
