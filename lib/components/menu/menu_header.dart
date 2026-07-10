import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:material_shapes/material_shapes.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.readingTimeValue,
    required this.libraryCountValue,
    this.onEditTap,
  });

  final String displayName;
  final String? avatarUrl;
  final String readingTimeValue;
  final String libraryCountValue;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: ShapeBorderClipper(
                  shape: MaterialShapeBorder(shape: MaterialShapes.pill),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: OfflineImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    fallback: Image.asset(
                      'images/avatar.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: _StatBadge(
                  value: readingTimeValue,
                  label: 'reading',
                  shape: MaterialShapes.sunny,
                  background: cs.tertiaryContainer,
                  foreground: cs.onTertiaryContainer,
                  angle: -0.14,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _StatBadge(
                  value: libraryCountValue,
                  label: 'in library',
                  shape: MaterialShapes.cookie9Sided,
                  background: cs.primaryContainer,
                  foreground: cs.onPrimaryContainer,
                  angle: 0.14,
                ),
              ),
            ],
          ),
          24.gap,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
              if (onEditTap != null) ...[
                8.gap,
                IconButton(
                  onPressed: onEditTap,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  tooltip: 'Edit profile',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.value,
    required this.label,
    required this.shape,
    required this.background,
    required this.foreground,
    required this.angle,
  });

  final String value;
  final String label;
  final RoundedPolygon shape;
  final Color background;
  final Color foreground;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;

    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 108,
        height: 108,
        decoration: ShapeDecoration(
          color: background,
          shape: MaterialShapeBorder(shape: shape),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.unbounded(
                textStyle: tt.titleLarge,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: foreground,
              ),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
