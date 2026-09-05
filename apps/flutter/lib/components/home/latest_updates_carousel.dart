import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/models/manga.dart';
import 'package:keihatsu/screens/MangaDetailsScreen.dart';

/// Hero-layout carousel — one large center item with smaller side peers.
///
/// Uses [CarouselView.weighted] with `[1, 7, 1]` flex weights, matching
/// Flutter's Material 3 hero carousel pattern.
class LatestUpdatesCarousel extends StatefulWidget {
  const LatestUpdatesCarousel({
    super.key,
    required this.mangas,
    required this.brandColor,
    required this.textColor,
    required this.onShowAll,
  });

  final List<Manga> mangas;
  final Color brandColor;
  final Color textColor;
  final VoidCallback onShowAll;

  static const double carouselHeight = 280;
  static const double cornerRadius = 28;

  @override
  State<LatestUpdatesCarousel> createState() => _LatestUpdatesCarouselState();
}

class _LatestUpdatesCarouselState extends State<LatestUpdatesCarousel> {
  late final CarouselController _controller = CarouselController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mangas.isEmpty) {
      return SizedBox(
        height: LatestUpdatesCarousel.carouselHeight,
        child: Center(
          child: Text(
            'No updates yet',
            style: TextStyle(color: widget.textColor.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    return SizedBox(
      height: LatestUpdatesCarousel.carouselHeight,
      child: CarouselView.weighted(
        controller: _controller,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemSnapping: true,
        flexWeights: const [2, 5, 2],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            LatestUpdatesCarousel.cornerRadius,
          ),
        ),
        onTap: (index) {
          _controller.animateToItem(
            index,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MangaDetailsScreen(manga: widget.mangas[index]),
            ),
          );
        },
        children: [
          for (final manga in widget.mangas)
            _HeroCarouselCard(
              manga: manga,
              borderRadius: LatestUpdatesCarousel.cornerRadius,
            ),
        ],
      ),
    );
  }
}

class _HeroCarouselCard extends StatelessWidget {
  const _HeroCarouselCard({required this.manga, required this.borderRadius});

  final Manga manga;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          OfflineImage(
            imageUrl: manga.thumbnailUrl,
            fit: BoxFit.cover,
            fallback: ColoredBox(
              color: Colors.grey.shade800,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                child: Text(
                  manga.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.2,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
