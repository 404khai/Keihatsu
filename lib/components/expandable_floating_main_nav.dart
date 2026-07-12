import 'package:flutter/material.dart';
import 'package:motor/motor.dart';
import 'package:provider/provider.dart';

import '../providers/floating_nav_provider.dart';
import '../screens/SearchScreen.dart';
import '../theme_provider.dart';

/// M3 Expressive horizontal floating toolbar — Flutter port of
/// [ExpandableHorizontalFloatingToolbarSample](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:compose/material3/material3/samples/src/main/java/androidx/compose/material3/samples/FloatingToolbarSamples.kt).
///
/// Collapsed: only the center search affordance remains.
/// Expanded: Home · Library · Search · History · Extensions · Profile.
class ExpandableFloatingMainNav extends StatelessWidget {
  const ExpandableFloatingMainNav({
    super.key,
    required this.currentIndex,
    required this.brandColor,
  });

  final int currentIndex;
  final Color brandColor;

  static const List<_NavDestination> _leading = [
    _NavDestination(
      index: 0,
      route: '/home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      index: 1,
      route: '/library',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
    ),
  ];

  static const List<_NavDestination> _trailing = [
    _NavDestination(
      index: 2,
      route: '/history',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    _NavDestination(
      index: 3,
      route: '/extensions',
      icon: Icons.extension_outlined,
      selectedIcon: Icons.extension_rounded,
    ),
    _NavDestination(
      index: 4,
      route: '/profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _navigate(BuildContext context, _NavDestination destination) {
    if (destination.index == currentIndex) return;
    Navigator.pushReplacementNamed(context, destination.route);
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final navProvider = Provider.of<FloatingNavProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDark = themeProvider.isDarkTheme;

    final Color toolbarColor = themeProvider.pureBlackDarkMode && isDark
        ? const Color(0xFF1A1A1A)
        : Color.alphaBlend(
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.92 : 0.88),
            cs.surface,
          );

    final double t = navProvider.expanded ? 1.0 : 0.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Center(
          child: SingleMotionBuilder(
            motion: MaterialSpringMotion.standardSpatialFast(),
            value: t,
            builder: (context, progress, child) {
              final double barWidth = _lerp(64, _maxBarWidth(context), progress);

              return Material(
                elevation: isDark ? 8 : 4,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                color: toolbarColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_lerp(32, 28, progress)),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: barWidth,
                  height: 56,
                  child: child,
                ),
              );
            },
            child: Row(
              children: [
                _SideDestinations(
                  destinations: _leading,
                  currentIndex: currentIndex,
                  expanded: t,
                  brandColor: brandColor,
                  onTap: (d) => _navigate(context, d),
                ),
                _SearchHeroButton(
                  expanded: t,
                  brandColor: brandColor,
                  onTap: () => _openSearch(context),
                ),
                _SideDestinations(
                  destinations: _trailing,
                  currentIndex: currentIndex,
                  expanded: t,
                  brandColor: brandColor,
                  onTap: (d) => _navigate(context, d),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _maxBarWidth(BuildContext context) {
    final double screen = MediaQuery.sizeOf(context).width;
    return (screen - 32).clamp(280, 420);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
}

class _NavDestination {
  const _NavDestination({
    required this.index,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });

  final int index;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
}

class _SideDestinations extends StatelessWidget {
  const _SideDestinations({
    required this.destinations,
    required this.currentIndex,
    required this.expanded,
    required this.brandColor,
    required this.onTap,
  });

  final List<_NavDestination> destinations;
  final int currentIndex;
  final double expanded;
  final Color brandColor;
  final ValueChanged<_NavDestination> onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Expanded(
      flex: expanded > 0.01 ? 1 : 0,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          widthFactor: expanded.clamp(0.0, 1.0),
          child: Opacity(
            opacity: expanded.clamp(0.0, 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final destination in destinations)
                  _NavIconButton(
                    icon: currentIndex == destination.index
                        ? destination.selectedIcon
                        : destination.icon,
                    selected: currentIndex == destination.index,
                    brandColor: brandColor,
                    unselectedColor: cs.onSurfaceVariant,
                    onTap: () => onTap(destination),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.selected,
    required this.brandColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color brandColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      color: selected ? brandColor : unselectedColor,
      tooltip: '',
    );
  }
}

class _SearchHeroButton extends StatelessWidget {
  const _SearchHeroButton({
    required this.expanded,
    required this.brandColor,
    required this.onTap,
  });

  final double expanded;
  final Color brandColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fill = Color.lerp(brandColor, cs.primaryContainer, 0.55)!;
    final Color iconColor = Color.lerp(cs.onPrimary, cs.onPrimaryContainer, 0.55)!;

    final double width = 44 + (20 * expanded);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * expanded),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: width,
            height: 44,
            child: Icon(Icons.search_rounded, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}
