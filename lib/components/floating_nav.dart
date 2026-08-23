import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';

/// M3 Expressive horizontal floating toolbar.
///
/// Home · Library · History · Extensions · Profile
class FloatingNav extends StatelessWidget {
  const FloatingNav({
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
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavDestination(
      index: 1,
      route: '/library',
      label: 'Library',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
    ),
    _NavDestination(
      index: 2,
      route: '/history',
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _NavDestination(
      index: 3,
      route: '/extensions',
      label: 'Extensions',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
    ),
    _NavDestination(
      index: 4,
      route: '/profile',
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _navigate(BuildContext context, _NavDestination destination) {
    if (destination.index == currentIndex) return;

    Navigator.pushReplacementNamed(
      context,
      destination.route,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;

    final bool isDark = themeProvider.isDarkTheme;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    final Color toolbarColor = themeProvider.pureBlackDarkMode && isDark
        ? const Color(0xFF1A1A1A)
        : Color.alphaBlend(
            cs.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.92 : 0.88,
            ),
            cs.surface,
          );

    return SizedBox(
      width: double.infinity,
      height: 56 + bottomInset + 8,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            bottomInset > 0 ? bottomInset : 8,
          ),
          child: Material(
            elevation: isDark ? 8 : 4,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            color: toolbarColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: _maxBarWidth(context),
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final destination in _destinations)
                    _NavItem(
                      destination: destination,
                      selected: currentIndex == destination.index,
                      brandColor: brandColor,
                      unselectedColor: cs.onSurfaceVariant,
                      onTap: () => _navigate(context, destination),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _maxBarWidth(BuildContext context) {
    final double screen = MediaQuery.sizeOf(context).width;
    return (screen - 32).clamp(320, 520);
  }
}

class _NavDestination {
  const _NavDestination({
    required this.index,
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final int index;
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.brandColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final Color brandColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = selected ? brandColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? brandColor.withValues(alpha: 0.30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                selected
                    ? destination.selectedIcon
                    : destination.icon,
                size: 25,
                color: iconColor,
              ),
            ),

            // const SizedBox(height: 2),
            //
            // Text(
            //   destination.label,
            //   style: GoogleFonts.delius(
            //     textStyle: TextStyle(
            //       fontSize: 13,
            //       fontWeight: FontWeight.bold,
            //       color: brandColor,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}