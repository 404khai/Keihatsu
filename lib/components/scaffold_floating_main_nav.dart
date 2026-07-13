import 'package:flutter/material.dart';
import 'package:motor/motor.dart';
import 'package:provider/provider.dart';

import '../providers/floating_nav_provider.dart';
import '../screens/SearchScreen.dart';
import '../theme_provider.dart';

/// Flutter port of [HorizontalFloatingToolbarAsScaffoldFabSample](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:compose/material3/material3/samples/src/main/java/androidx/compose/material3/samples/FloatingToolbarSamples.kt).
///
/// Nav icons sit to the left of a fixed search FAB on the end. On scroll collapse
/// they slide right into the search button; scrolling up expands them back out.
class ScaffoldFloatingMainNav extends StatelessWidget {
  const ScaffoldFloatingMainNav({
    super.key,
    required this.currentIndex,
    required this.brandColor,
  });

  final int currentIndex;
  final Color brandColor;

  static const List<_NavDestination> _destinations = [
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
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    final Color toolbarColor = themeProvider.pureBlackDarkMode && isDark
        ? const Color(0xFF1A1A1A)
        : Color.alphaBlend(
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.92 : 0.88),
            cs.surface,
          );

    final double t = navProvider.expanded ? 1.0 : 0.0;

    return SizedBox(
      width: double.infinity,
      height: 56 + bottomInset + 8,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset : 8),
          child: SingleMotionBuilder(
            motion: MaterialSpringMotion.standardSpatialFast(),
            value: t,
            builder: (context, progress, _) {
              final double visibility = progress.clamp(0.0, 1.0);
              final bool collapsed = visibility < 0.02;

              return Material(
                elevation: isDark ? 8 : 4,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                color: toolbarColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: collapsed ? 0 : visibility,
                          child: Opacity(
                            opacity: visibility,
                            child: Transform.translate(
                              offset: Offset(48 * (1 - visibility), 0),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final destination in _destinations)
                                      _NavIconButton(
                                        icon: currentIndex == destination.index
                                            ? destination.selectedIcon
                                            : destination.icon,
                                        selected:
                                            currentIndex == destination.index,
                                        brandColor: brandColor,
                                        unselectedColor: cs.onSurfaceVariant,
                                        onTap: () =>
                                            _navigate(context, destination),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _SearchFabButton(
                        brandColor: brandColor,
                        onTap: () => _openSearch(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
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
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _SearchFabButton extends StatelessWidget {
  const _SearchFabButton({
    required this.brandColor,
    required this.onTap,
  });

  final Color brandColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fill = Color.lerp(brandColor, cs.primaryContainer, 0.55)!;
    final Color iconColor =
        Color.lerp(cs.onPrimary, cs.onPrimaryContainer, 0.55)!;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                Icons.search_rounded,
                color: iconColor,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
