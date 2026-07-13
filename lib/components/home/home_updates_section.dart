import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/data/mock_home_updates.dart';
import 'package:material_shapes/material_shapes.dart';

/// Grouped Updates list — Today / Tomorrow rows with M3E shaped thumbnails.
class HomeUpdatesSection extends StatelessWidget {
  const HomeUpdatesSection({
    super.key,
    required this.brandColor,
    required this.textColor,
    required this.onSeeMore,
    required this.groups,
  });

  final Color brandColor;
  final Color textColor;
  final VoidCallback onSeeMore;
  final List<HomeUpdateGroup> groups;

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
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: textColor,
                    fontSize: 24,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeMore,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onPrimary,
                  backgroundColor: brandColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'See More',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              group.label,
              style: TextStyle(
                color: muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          for (final entry in group.entries)
            _UpdateRow(
              entry: entry,
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
    required this.entry,
    required this.textColor,
    required this.mutedColor,
    required this.iconBackground,
    required this.iconColor,
  });

  final HomeUpdateEntry entry;
  final Color textColor;
  final Color mutedColor;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(
              shape: MaterialShapeBorder(shape: entry.shape),
            ),
            child: Image.asset(
              entry.thumbnailAsset,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade800,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: Colors.white54, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
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
                  entry.chapters,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _TrailingAction(
            scheduled: entry.scheduled,
            background: iconBackground,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.scheduled,
    required this.background,
    required this.color,
  });

  final bool scheduled;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (scheduled)
            Icon(Icons.calendar_today_outlined, color: color, size: 22)
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Icon(Icons.download_rounded, color: color, size: 20),
            ),
          if (scheduled)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_rounded, color: color, size: 10),
              ),
            ),
        ],
      ),
    );
  }
}
