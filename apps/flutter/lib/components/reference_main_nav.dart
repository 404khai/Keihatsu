import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/SearchScreen.dart';
import '../theme_provider.dart';

/// Floating navigation styled after the reference toolbar: the active
/// destination expands into an icon-and-label chip, while search stays in a
/// separate rounded button.
class ReferenceMainNav extends StatelessWidget {
  const ReferenceMainNav({
    super.key,
    required this.currentIndex,
    required this.brandColor,
  });

  final int currentIndex;
  final Color brandColor;

  // The selected route is this tall; the surrounding pill adds a small inset
  // so the active tab does not touch the navbar background.
  static const double _routeBarHeight = 76;
  static const double _selectedTabGap = 4;

  static const List<_Destination> _destinations = [
    _Destination(
      index: 0,
      route: '/home',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _Destination(
      index: 1,
      route: '/library',
      label: 'Library',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
    ),
    _Destination(
      index: 2,
      route: '/history',
      label: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
    ),
    _Destination(
      index: 3,
      route: '/extensions',
      label: 'Plugins',
      icon: Icons.extension_outlined,
      selectedIcon: Icons.extension_rounded,
    ),
    _Destination(
      index: 4,
      route: '/profile',
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _navigate(BuildContext context, _Destination destination) {
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
    final Color selectedColor = Color.lerp(
      toolbarColor,
      brandColor,
      isDark ? 0.44 : 0.30,
    )!;
    final Color searchColor = Color.lerp(
      brandColor,
      cs.primaryContainer,
      0.20,
    )!;

    return SizedBox(
      width: double.infinity,
      height: _routeBarHeight + (_selectedTabGap * 2) + bottomInset + 8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          bottomInset > 0 ? bottomInset : 8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                elevation: isDark ? 8 : 4,
                shadowColor: Colors.black.withValues(alpha: 0.35),
                color: toolbarColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: _routeBarHeight + (_selectedTabGap * 2),
                  child: Row(
                    children: [
                      for (final destination in _destinations)
                        Expanded(
                          flex: destination.index == currentIndex ? 4 : 1,
                          child: _DestinationButton(
                            destination: destination,
                            selected: destination.index == currentIndex,
                            routeBarHeight: _routeBarHeight,
                            selectedTabGap: _selectedTabGap,
                            selectedColor: selectedColor,
                            selectedForeground: cs.onSurface,
                            foreground: cs.onSurfaceVariant,
                            onTap: () => _navigate(context, destination),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              elevation: isDark ? 8 : 4,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              color: searchColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openSearch(context),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.search_rounded,
                    color: cs.onPrimary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
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

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.destination,
    required this.selected,
    required this.routeBarHeight,
    required this.selectedTabGap,
    required this.selectedColor,
    required this.selectedForeground,
    required this.foreground,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final double routeBarHeight;
  final double selectedTabGap;
  final Color selectedColor;
  final Color selectedForeground;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: selected ? 6 : 2,
        vertical: selected ? selectedTabGap : 6,
      ),
      child: SizedBox(
        height: selected ? routeBarHeight : null,
        child: Material(
          color: selected ? selectedColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: selected ? 25 : 20,
                    color: selected ? selectedForeground : foreground,
                  ),
                  if (selected) ...[
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selectedForeground,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
