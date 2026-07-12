import 'package:flutter/material.dart';
import 'package:keihatsu/common/shape_values.dart';
import 'package:keihatsu/components/downloads/download_tile.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:material_wavy_progress_indicator/material_wavy_progress_indicator.dart';

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
  });

  final String mangaTitle;
  final String? mangaThumbnail;
  final List<DownloadQueueItem> chapters;
  final BorderRadius? borderRadius;
  final bool initiallyExpanded;

  @override
  State<DownloadMangaGroup> createState() => _DownloadMangaGroupState();
}

class _DownloadMangaGroupState extends State<DownloadMangaGroup> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _hasMultipleChapters => widget.chapters.length > 1;

  DownloadQueueItem get _primaryChapter {
    final downloading = widget.chapters.where((c) => c.status == 1);
    if (downloading.isNotEmpty) return downloading.first;
    return widget.chapters.first;
  }

  String _statusLabel() {
    final int downloading =
        widget.chapters.where((c) => c.status == 1).length;
    final int queued = widget.chapters.where((c) => c.status == 0).length;
    final int paused = widget.chapters.where((c) => c.status == 4).length;

    if (downloading > 0 && queued > 0) {
      return '$downloading downloading · $queued queued';
    }
    if (downloading > 0) return '$downloading chapter${downloading == 1 ? '' : 's'} downloading';
    if (queued > 0) return '$queued chapter${queued == 1 ? '' : 's'} queued';
    if (paused > 0) return 'Paused';
    return '${widget.chapters.length} chapter${widget.chapters.length == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final DownloadQueueItem primary = _primaryChapter;

    return Material(
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(MenuSection.innerRadius),
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
                          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
                    _StatusIndicator(item: primary),
                ],
              ),
            ),
          ),
          if (_hasMultipleChapters && _expanded) ...[
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            for (int i = 0; i < widget.chapters.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 78,
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(78, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chapters[i].chapterName,
                            style: tt.bodyMedium,
                          ),
                          2.gap,
                          Text(
                            sizeLabelMb(40 + widget.chapters[i].chapterNumber * 8),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusIndicator(item: widget.chapters[i]),
                  ],
                ),
              ),
            ],
            8.gap,
          ],
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.item});

  final DownloadQueueItem item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    switch (item.status) {
      case 1:
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularWavyProgressIndicator(
                value: item.progress.clamp(0.0, 1.0),
              ),
              Icon(Icons.stop_rounded, size: 20, color: cs.primary),
            ],
          ),
        );
      case 0:
        return SizedBox(
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
        );
      case 4:
        return Icon(Icons.pause_circle_outline, color: cs.tertiary, size: 28);
      case 3:
        return Icon(Icons.error_outline, color: cs.error, size: 28);
      default:
        return const SizedBox(width: 44, height: 44);
    }
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
