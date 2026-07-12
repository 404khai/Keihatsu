import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/downloads/download_manga_group.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';

class DownloadSection extends StatelessWidget {
  const DownloadSection({
    super.key,
    required this.label,
    this.image,
    this.meta,
    this.action,
    required this.children,
  });

  final String label;
  final String? image;
  final String? meta;
  final Widget? action;
  final List<DownloadMangaGroup> children;

  BorderRadius _radiusFor(int index) {
    const Radius outer = Radius.circular(MenuSection.outerRadius);
    const Radius inner = Radius.circular(MenuSection.innerRadius);

    return BorderRadius.vertical(
      top: index == 0 ? outer : inner,
      bottom: index == children.length - 1 ? outer : inner,
    );
  }

  DownloadMangaGroup _positioned(DownloadMangaGroup group, int index) {
    return DownloadMangaGroup(
      key: group.key,
      mangaTitle: group.mangaTitle,
      mangaThumbnail: group.mangaThumbnail,
      chapters: group.chapters,
      borderRadius: _radiusFor(index),
      initiallyExpanded: group.initiallyExpanded,
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
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.extension_outlined,
                      size: 22,
                      color: cs.primary,
                    ),
                  ),
                ),
                10.gap,
              ],
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
