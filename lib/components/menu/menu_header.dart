import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/profile/shaped_action_button.dart';
import 'package:material_shapes/material_shapes.dart';

/// Menu page header: pill avatar with expressive stat badges and name below.
class MenuHeader extends StatelessWidget {
  const MenuHeader({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.statValue,
    required this.statLabel,
    required this.secondaryStatValue,
    required this.secondaryStatLabel,
    this.onEditTap,
    this.belowName,
    this.bio,
    this.memberSince,
    this.location,
    this.badgeIcon,
    this.onShareTap,
    this.showProfileActions = false,
  });

  final String displayName;
  final String? avatarUrl;
  final String statValue;
  final String statLabel;
  final String secondaryStatValue;
  final String secondaryStatLabel;
  final VoidCallback? onEditTap;
  final List<Widget>? belowName;
  final String? bio;
  final String? memberSince;
  final String? location;
  final IconData? badgeIcon;
  final VoidCallback? onShareTap;
  final bool showProfileActions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80, bottom: 4, left: 16, right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 188,
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: MaterialShapeBorder(shape: MaterialShapes.pill),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: OfflineImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        fallback: Image.asset(
                          'images/jake.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  top: -6,
                  child: _StatBadge(
                    value: statValue,
                    label: statLabel,
                    shape: MaterialShapes.sunny,
                    background: cs.tertiaryContainer,
                    foreground: cs.onTertiaryContainer,
                    angle: -0.14,
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: _StatBadge(
                    value: secondaryStatValue,
                    label: secondaryStatLabel,
                    shape: MaterialShapes.cookie9Sided,
                    background: cs.primaryContainer,
                    foreground: cs.onPrimaryContainer,
                    angle: 0.14,
                  ),
                ),
              ],
            ),
          ),
          8.gap,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              if (badgeIcon != null) ...[
                8.gap,
                Container(
                  width: 28,
                  height: 28,
                  decoration: ShapeDecoration(
                    color: cs.tertiary,
                    shape: MaterialShapeBorder(shape: MaterialShapes.circle),
                  ),
                  child: Icon(badgeIcon, size: 16, color: cs.onTertiary),
                ),
              ] else if (onEditTap != null && !showProfileActions) ...[
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
          if (bio != null) ...[
            6.gap,
            Text(
              bio!,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
          if (memberSince != null || location != null) ...[
            10.gap,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (memberSince != null) ...[
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  4.gap,
                  Text(
                    'Member since $memberSince',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (memberSince != null && location != null) ...[
                  16.gap,
                ],
                if (location != null) ...[
                  Icon(Icons.location_on_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  4.gap,
                  Text(
                    location!,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
          if (showProfileActions) ...[
            16.gap,
            Row(
              children: [
                Expanded(
                  child: ShapedActionButton(
                    onTap: onShareTap ?? () {},
                    rest: MaterialShapes.pill,
                    pressed: MaterialShapes.cookie7Sided,
                    outlined: true,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ios_share_rounded,
                            size: 18, color: cs.onSurface),
                        8.gap,
                        Text(
                          'Share Profile',
                          style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                12.gap,
                ShapedActionButton(
                  onTap: onEditTap ?? () {},
                  rest: MaterialShapes.circle,
                  pressed: MaterialShapes.sunny,
                  outlined: true,
                  height: 44,
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    width: 44,
                    child: Icon(Icons.edit_outlined,
                        size: 20, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ],
          if (belowName != null) ...belowName!,
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
        width: 88,
        height: 88,
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
                textStyle: tt.titleMedium,
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
