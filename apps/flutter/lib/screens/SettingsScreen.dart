import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../components/CustomBackButton.dart';
import 'LibrarySettingsScreen.dart';
import 'PrivacySettingsScreen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.palette_outlined,
      title: 'Appearance',
      subtitle: 'Themes, dark mode, display',
    ),
    (
      icon: Icons.library_books_outlined,
      title: 'Library',
      subtitle: 'Categories, global update, badges',
    ),
    (
      icon: Icons.menu_book_outlined,
      title: 'Reader',
      subtitle: 'Reading mode, display, navigation',
    ),
    (
      icon: Icons.download_outlined,
      title: 'Downloads',
      subtitle: 'Download location, save chapters',
    ),
    (
      icon: Icons.explore_outlined,
      title: 'Browse',
      subtitle: 'Extensions, global search',
    ),
    (
      icon: Icons.sync_outlined,
      title: 'Tracking',
      subtitle: 'Sync with services like MyAnimeList',
    ),
    (
      icon: Icons.shield_outlined,
      title: 'Privacy',
      subtitle: 'Profile visibility and privacy',
    ),
    (
      icon: Icons.tune_outlined,
      title: 'Advanced',
      subtitle: 'Backup, clear cache, logs',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color backgroundColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surface;
    final Color appBarColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surfaceContainer;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Settings',
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: cs.onSurface,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (int i = 0; i < _items.length; i++)
            _SettingsTile(
              icon: _items[i].icon,
              title: _items[i].title,
              subtitle: _items[i].subtitle,
              iconBackground: _iconBackground(cs, i),
              iconColor: _iconColor(cs, i),
              onTap: () => _onTap(context, i),
              titleStyle: tt.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              subtitleStyle: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              tileColor: cs.surfaceContainer,
              chevronColor: cs.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  Color _iconBackground(ColorScheme cs, int index) {
    return switch (index) {
      0 => cs.primaryContainer,
      1 => cs.secondaryContainer,
      2 => cs.tertiaryContainer,
      3 => cs.primaryContainer.withValues(alpha: 0.65),
      4 => cs.surfaceContainerHighest,
      5 => cs.secondaryContainer.withValues(alpha: 0.75),
      6 => cs.errorContainer,
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _iconColor(ColorScheme cs, int index) {
    return switch (index) {
      0 => cs.onPrimaryContainer,
      1 => cs.onSecondaryContainer,
      2 => cs.onTertiaryContainer,
      3 => cs.onPrimaryContainer,
      4 => cs.onSurfaceVariant,
      5 => cs.onSecondaryContainer,
      6 => cs.onErrorContainer,
      _ => cs.onSurfaceVariant,
    };
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/appearance');
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LibrarySettingsScreen(),
          ),
        );
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacySettingsScreen(),
          ),
        );
      default:
        break;
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.tileColor,
    required this.chevronColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color tileColor;
  final Color chevronColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: tileColor,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: subtitleStyle),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: chevronColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
