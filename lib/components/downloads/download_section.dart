import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/downloads/download_tile.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';

class DownloadSection extends StatelessWidget {
  const DownloadSection({
    super.key,
    required this.label,
    this.meta,
    this.action,
    required this.children,
  });

  final String label;
  final String? meta;
  final Widget? action;
  final List<DownloadTile> children;

  BorderRadius _radiusFor(int index) {
    const Radius outer = Radius.circular(MenuSection.outerRadius);
    const Radius inner = Radius.circular(MenuSection.innerRadius);

    return BorderRadius.vertical(
      top: index == 0 ? outer : inner,
      bottom: index == children.length - 1 ? outer : inner,
    );
  }

  DownloadTile _positioned(DownloadTile tile, int index) {
    return DownloadTile(
      key: tile.key,
      item: tile.item,
      onTap: tile.onTap,
      onDelete: tile.onDelete,
      removing: tile.removing,
      onRemoved: tile.onRemoved,
      borderRadius: _radiusFor(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.unbounded(
                    textStyle: tt.labelLarge,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: cs.primary,
                  ),
                ),
              ),
              if (action != null)
                action!
              else if (meta != null)
                Text(
                  meta!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) MenuSection.tileGap.gap,
          _positioned(children[i], i),
        ],
      ],
    );
  }
}
