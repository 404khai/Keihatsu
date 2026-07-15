import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/OfflineImage.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/profile/shaped_action_button.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:motor/motor.dart';

/// One expressive stat shown on a profile header badge.
class MenuHeaderStat {
  const MenuHeaderStat({
    required this.value,
    required this.label,
    required this.shape,
  });

  final String value;
  final String label;
  final RoundedPolygon shape;
}

/// Menu page header: pill avatar with expressive stat badges and name below.
class MenuHeader extends StatefulWidget {
  const MenuHeader({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.stats,
    this.onEditTap,
    this.belowName,
    this.bio,
    this.memberSince,
    this.location,
    this.badgeIcon,
    this.onShareTap,
    this.showProfileActions = false,
    this.statRotationInterval = const Duration(seconds: 5),
    this.statStagger = const Duration(seconds: 2),
  });

  final String displayName;
  final String? avatarUrl;
  final List<MenuHeaderStat> stats;
  final VoidCallback? onEditTap;
  final List<Widget>? belowName;
  final String? bio;
  final String? memberSince;
  final String? location;
  final IconData? badgeIcon;
  final VoidCallback? onShareTap;
  final bool showProfileActions;
  final Duration statRotationInterval;
  final Duration statStagger;

  @override
  State<MenuHeader> createState() => _MenuHeaderState();
}

class _MenuHeaderState extends State<MenuHeader> {
  static const List<int> _leftCycle = [0, 2];
  static const List<int> _rightCycle = [1, 3];

  int _leftCyclePos = 0;
  int _rightCyclePos = 0;
  Timer? _leftTimer;
  Timer? _rightTimer;

  @override
  void initState() {
    super.initState();
    if (widget.stats.length >= 4) {
      _leftTimer = Timer.periodic(widget.statRotationInterval, (_) {
        if (!mounted) return;
        setState(() {
          _leftCyclePos = (_leftCyclePos + 1) % _leftCycle.length;
        });
      });
      Future<void>.delayed(widget.statStagger, _startRightRotation);
    }
  }

  void _startRightRotation() {
    if (!mounted || widget.stats.length < 4) return;
    _rightTimer?.cancel();
    setState(() {
      _rightCyclePos = (_rightCyclePos + 1) % _rightCycle.length;
    });
    _rightTimer = Timer.periodic(widget.statRotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _rightCyclePos = (_rightCyclePos + 1) % _rightCycle.length;
      });
    });
  }

  @override
  void dispose() {
    _leftTimer?.cancel();
    _rightTimer?.cancel();
    super.dispose();
  }

  MenuHeaderStat? _statAt(int index) {
    if (index < 0 || index >= widget.stats.length) return null;
    return widget.stats[index];
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final MenuHeaderStat? leftStat = widget.stats.length >= 4
        ? _statAt(_leftCycle[_leftCyclePos])
        : _statAt(0);
    final MenuHeaderStat? rightStat = widget.stats.length >= 4
        ? _statAt(_rightCycle[_rightCyclePos])
        : _statAt(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 70, bottom: 4, left: 16, right: 16),
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
                        imageUrl: widget.avatarUrl,
                        fit: BoxFit.cover,
                        fallback: Image.asset(
                          'images/jake.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                if (leftStat != null)
                  Positioned(
                    left: -6,
                    top: -6,
                    child: _MorphingStatBadge(
                      stat: leftStat,
                      background: cs.tertiaryContainer,
                      foreground: cs.onTertiaryContainer,
                      angle: -0.14,
                    ),
                  ),
                if (rightStat != null)
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: _MorphingStatBadge(
                      stat: rightStat,
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
                  widget.displayName,
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              if (widget.badgeIcon != null) ...[
                8.gap,
                Container(
                  width: 28,
                  height: 28,
                  decoration: ShapeDecoration(
                    color: cs.tertiary,
                    shape: MaterialShapeBorder(shape: MaterialShapes.circle),
                  ),
                  child: Icon(widget.badgeIcon, size: 16, color: cs.onTertiary),
                ),
              ] else if (widget.onEditTap != null && !widget.showProfileActions) ...[
                8.gap,
                IconButton(
                  onPressed: widget.onEditTap,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  tooltip: 'Edit profile',
                ),
              ],
            ],
          ),
          if (widget.bio != null) ...[
            6.gap,
            Text(
              widget.bio!,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
          if (widget.memberSince != null || widget.location != null) ...[
            10.gap,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.memberSince != null) ...[
                  Icon(Icons.calendar_month_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  4.gap,
                  Text(
                    'Member since ${widget.memberSince}',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
                if (widget.memberSince != null && widget.location != null) ...[
                  16.gap,
                ],
                if (widget.location != null) ...[
                  const _DuotoneFireIcon(size: 14),
                  4.gap,
                  Text(
                    widget.location!,
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
          if (widget.showProfileActions) ...[
            16.gap,
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onShareTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHigh,
                      foregroundColor: cs.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: Icon(Icons.ios_share_rounded,
                        size: 18, color: cs.onSurface),
                    label: Text(
                      'Share Profile',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                12.gap,
                ShapedActionButton(
                  onTap: widget.onEditTap ?? () {},
                  rest: MaterialShapes.circle,
                  pressed: MaterialShapes.sunny,
                  color: cs.surfaceContainerHigh,
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
          if (widget.belowName != null) ...widget.belowName!,
        ],
      ),
    );
  }
}

class _DuotoneFireIcon extends StatelessWidget {
  const _DuotoneFireIcon({required this.size});

  final double size;

  static const Color _background = Color(0xFFE53935);
  static const Color _foreground = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            color: _background,
            size: size,
          ),
          Icon(
            Icons.local_fire_department,
            color: _foreground,
            size: size * 0.68,
          ),
        ],
      ),
    );
  }
}

class _MorphingStatBadge extends StatefulWidget {
  const _MorphingStatBadge({
    super.key,
    required this.stat,
    required this.background,
    required this.foreground,
    required this.angle,
  });

  final MenuHeaderStat stat;
  final Color background;
  final Color foreground;
  final double angle;

  @override
  State<_MorphingStatBadge> createState() => _MorphingStatBadgeState();
}

class _MorphingStatBadgeState extends State<_MorphingStatBadge> {
  late RoundedPolygon _fromShape;
  double _morphTarget = 1;

  @override
  void initState() {
    super.initState();
    _fromShape = widget.stat.shape;
  }

  @override
  void didUpdateWidget(covariant _MorphingStatBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stat.shape != widget.stat.shape ||
        oldWidget.stat.value != widget.stat.value ||
        oldWidget.stat.label != widget.stat.label) {
      _fromShape = oldWidget.stat.shape;
      _morphTarget = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _morphTarget = 1);
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _fromShape = widget.stat.shape);
        });
      });
    }
  }

  ShapeBorder _shapeAt(double t) {
    final MaterialShapeBorder target =
        MaterialShapeBorder(shape: widget.stat.shape);
    if (t <= 0) {
      return MaterialShapeBorder(shape: _fromShape);
    }
    if (t >= 1) return target;
    final MaterialShapeBorder from = MaterialShapeBorder(shape: _fromShape);
    return from.lerpTo(target, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;

    return Transform.rotate(
      angle: widget.angle,
      child: SingleMotionBuilder(
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
        value: _morphTarget,
        builder: (context, t, _) {
          return SizedBox(
            width: 88,
            height: 88,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: _shapeAt(t)),
              child: ColoredBox(
                color: widget.background,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Text(
                        widget.stat.value,
                        key: ValueKey(widget.stat.value),
                        style: GoogleFonts.unbounded(
                          textStyle: tt.titleMedium,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: widget.foreground,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Text(
                        widget.stat.label,
                        key: ValueKey(widget.stat.label),
                        style: tt.labelSmall?.copyWith(color: widget.foreground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
