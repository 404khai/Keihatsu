import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/models/manga.dart';
import 'package:keihatsu/screens/MangaDetailsScreen.dart';
import 'package:material_shapes/material_shapes.dart';

/// Grouped Updates list — Today / Tomorrow rows with M3E shaped thumbnails.
class HomeUpdatesSection extends StatelessWidget {
  const HomeUpdatesSection({
    super.key,
    required this.brandColor,
    required this.textColor,
    required this.onSeeMore,
    required this.mangas,
  });

  final Color brandColor;
  final Color textColor;
  final VoidCallback onSeeMore;
  final List<Manga> mangas;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color muted = cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Updates',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: textColor,
                    fontSize: 20,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeMore,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onPrimary,
                  backgroundColor: brandColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'See More',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (mangas.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text('No updates available', style: TextStyle(color: muted)),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Latest from your sources',
              style: TextStyle(
                color: muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          for (final manga in mangas.take(10))
            _UpdateRow(
              manga: manga,
              textColor: textColor,
              mutedColor: muted,
              iconBackground: cs.surfaceContainerHighest,
              iconColor: cs.onSurfaceVariant,
            ),
        ],
      ],
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.manga,
    required this.textColor,
    required this.mutedColor,
    required this.iconBackground,
    required this.iconColor,
  });

  final Manga manga;
  final Color textColor;
  final Color mutedColor;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MangaDetailsScreen(manga: manga)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            ClipPath(
              clipper: ShapeBorderClipper(
                shape: MaterialShapeBorder(shape: MaterialShapes.cookie4Sided),
              ),
              child: OfflineImage(
                imageUrl: manga.thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 56,
                  height: 56,
                  color: iconBackground,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    manga.status ?? manga.sourceId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mutedColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: iconColor),
          ],
        ),
      ),
    );
  }
}
