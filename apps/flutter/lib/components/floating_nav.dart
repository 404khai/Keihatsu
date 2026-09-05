import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/SearchScreen.dart';
import '../theme_provider.dart';

/// Fixed floating navigation with a separate trailing search button.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.currentIndex,
    required this.brandColor,
  });

  final int currentIndex;
  final Color brandColor;

  static const double _barHeight = 56;
  static const double _searchSize = 50;
  static const double _gap = 8;

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
      icon: Icons.history_outlined,
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
      MaterialPageRoute(builder: (_) => const SearchScreen()),
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
            cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.92 : 0.88),
            cs.surface,
          );
    final Color searchColor = Color.lerp(
      brandColor,
      cs.primaryContainer,
      0.20,
    )!;

    return SizedBox(
      width: double.infinity,
      height: _barHeight + bottomInset + 8,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            bottomInset > 0 ? bottomInset : 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Material(
                  elevation: isDark ? 8 : 4,
                  shadowColor: Colors.black.withValues(alpha: 0.35),
                  color: toolbarColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: _barHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              const SizedBox(width: _gap),
              _SearchFabButton(
                brandColor: searchColor,
                isDark: isDark,
                onTap: () => _openSearch(context),
              ),
            ],
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
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 8 : 5,
            vertical: selected ? 8 : 7,
          ),
          decoration: BoxDecoration(
            color: selected
                ? brandColor.withValues(alpha: 0.30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: selected ? 30 : 25,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _SearchFabButton extends StatelessWidget {
  const _SearchFabButton({
    required this.brandColor,
    required this.isDark,
    required this.onTap,
  });

  final Color brandColor;
  final bool isDark;
  final VoidCallback onTap;

  static const double _size = FloatingNav._searchSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: isDark ? 8 : 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      color: brandColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF1C1C1C),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
