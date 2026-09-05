import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:motor/motor.dart';

String sizeLabelMb(double megabytes) {
  if (megabytes >= 1024) {
    return '${(megabytes / 1024).toStringAsFixed(1)} GB';
  }
  return '${megabytes.round()} MB';
}

class DownloadTile extends StatelessWidget {
  const DownloadTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
    this.removing = false,
    this.onRemoved,
    this.borderRadius,
  });

  final DownloadQueueItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool removing;
  final VoidCallback? onRemoved;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return _RemovalCollapse(
      removing: removing,
      onRemoved: onRemoved,
      child: Material(
        color: cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius:
              borderRadius ?? BorderRadius.circular(MenuSection.innerRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              children: [
                ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: MaterialShapeBorder(shape: MaterialShapes.softBurst),
                  ),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: _CoverImage(path: item.mangaThumbnail),
                  ),
                ),
                14.gap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _capitalizeExtensionName(item.extensionName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      2.gap,
                      Text(
                        item.mangaTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      2.gap,
                      Text(
                        item.chapterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      4.gap,
                      Text(
                        _sizeEstimate(item),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                12.gap,
                _trailing(context, cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sizeEstimate(DownloadQueueItem item) {
    final double mb = 40 + (item.chapterNumber * 8);
    return sizeLabelMb(mb);
  }

  String _capitalizeExtensionName(String name) {
    if (name.isEmpty) return name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  Widget _trailing(BuildContext context, ColorScheme cs) {
    switch (item.status) {
      case 1:
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: item.progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
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
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: 0,
                  strokeWidth: 3,
                  color: cs.outlineVariant,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        );
      case 2:
        if (onDelete == null) {
          return Container(
            width: 28,
            height: 28,
            decoration: ShapeDecoration(
              color: cs.tertiaryContainer,
              shape: MaterialShapeBorder(shape: MaterialShapes.cookie7Sided),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: cs.onTertiaryContainer,
            ),
          );
        }
        return _DeleteButton(onPressed: onDelete!);
      default:
        return Icon(Icons.error_outline, color: cs.error, size: 22);
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

    final image = path!.startsWith('/') || path!.startsWith('file:')
        ? Image.file(
            File(
              path!.startsWith('file:') ? Uri.parse(path!).toFilePath() : path!,
            ),
            fit: BoxFit.cover,
          )
        : Image.asset(path!, fit: BoxFit.cover);

    return image;
  }
}

class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double target = _pressed ? 1.0 : 0.0;
    final ShapeBorder circle = MaterialShapeBorder(
      shape: MaterialShapes.circle,
    );
    final ShapeBorder sunny = MaterialShapeBorder(shape: MaterialShapes.sunny);

    return Tooltip(
      message: 'Remove download',
      child: InkResponse(
        onTap: widget.onPressed,
        onHighlightChanged: (highlighted) {
          setState(() => _pressed = highlighted);
        },
        radius: 26,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SingleMotionBuilder(
          value: target,
          motion: const MaterialSpringMotion.expressiveSpatialFast(),
          builder: (context, spatial, child) {
            return SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Transform.scale(
                  scale: 1 + 0.12 * spatial,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: ShapeDecoration(
                      color: cs.errorContainer.withValues(alpha: spatial),
                      shape: ShapeBorder.lerp(circle, sunny, spatial) ?? circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color.lerp(
                        cs.onSurfaceVariant,
                        cs.onErrorContainer,
                        spatial,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RemovalCollapse extends StatefulWidget {
  const _RemovalCollapse({
    required this.removing,
    required this.onRemoved,
    required this.child,
  });

  final bool removing;
  final VoidCallback? onRemoved;
  final Widget child;

  @override
  State<_RemovalCollapse> createState() => _RemovalCollapseState();
}

class _RemovalCollapseState extends State<_RemovalCollapse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onRemoved?.call();
    });
    if (widget.removing) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _RemovalCollapse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing && !oldWidget.removing) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: Tween<double>(
        begin: 1,
        end: 0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      axisAlignment: -1,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(_controller),
        child: widget.child,
      ),
    );
  }
}
