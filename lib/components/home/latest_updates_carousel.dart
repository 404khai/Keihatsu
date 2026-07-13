import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/common/shape_values.dart';
import 'package:keihatsu/models/manga.dart';
import 'package:keihatsu/screens/MangaDetailsScreen.dart';
import 'package:material_shapes/material_shapes.dart';

/// Flutter port of [CarouselWithShowAllButtonSample](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:compose/material3/material3/samples/src/main/java/androidx/compose/material3/samples/CarouselSamples.kt)
/// using a horizontal multi-browse layout and trailing show-all action.
class LatestUpdatesCarousel extends StatelessWidget {
  const LatestUpdatesCarousel({
    super.key,
    required this.mangas,
    required this.brandColor,
    required this.textColor,
    required this.onShowAll,
    this.loading = false,
  });

  final List<Manga> mangas;
  final Color brandColor;
  final Color textColor;
  final VoidCallback onShowAll;
  final bool loading;

  static const double _carouselHeight = 221;
  static const double _itemHeight = 205;
  static const double _preferredItemWidth = 186;
  static const double _itemSpacing = 8;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: _carouselHeight,
        child: Center(child: CircularProgressIndicator(color: brandColor)),
      );
    }

    if (mangas.isEmpty) {
      return SizedBox(
        height: _carouselHeight,
        child: Center(
          child: Text(
            'No updates yet',
            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _carouselHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: mangas.length,
            separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
            itemBuilder: (context, index) {
              final manga = mangas[index];
              return _CarouselItem(
                manga: manga,
                width: _preferredItemWidth,
                height: _itemHeight,
                shape: index.isEven ? ShapeValues.cover : ShapeValues.coverFocused,
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                foregroundColor: cs.onPrimary,
                backgroundColor: brandColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Show all',
                style: GoogleFonts.unbounded(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    required this.manga,
    required this.width,
    required this.height,
    required this.shape,
  });

  final Manga manga;
  final double width;
  final double height;
  final RoundedPolygon shape;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailsScreen(manga: manga),
          ),
        );
      },
      child: SizedBox(
        width: width,
        height: height,
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: MaterialShapeBorder(shape: shape),
          ),
          child: Image.network(
            manga.thumbnailUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade800,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
