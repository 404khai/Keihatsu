import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const List<({String name, Color brand, Color bg})> _presets = [
    (name: 'Pebble', brand: Color(0xFF9CB4B3), bg: Color(0xFFEFEFEF)),
    (name: 'Coral', brand: Color(0xFFE29578), bg: Color(0xFFFFEBE3)),
    (name: 'Sand', brand: Color(0xFF9F956C), bg: Color(0xFFF5F0E1)),
    (name: 'Rose Petal', brand: Color(0xFFFFBEEB), bg: Color(0xFFFBEBF7)),
    (name: 'Saffron', brand: Color(0xFFF4C430), bg: Color(0xFFFFFACF)),
    (name: 'Pumpkin', brand: Color(0xFFF97316), bg: Color(0xFFFFEDD5)),
    (name: 'RainForest', brand: Color(0xFF0DB14C), bg: Color(0xFFE8F5E9)),
    (name: 'Lilac', brand: Color(0xFFB65FCF), bg: Color(0xFFF5D1FF)),
    (name: 'Raspberry', brand: Color(0xFFFF256D), bg: Color(0xFFFFD4E5)),
    (name: 'Tropical Kiwi', brand: Color(0xFF83A42E), bg: Color(0xFFF1FBEB)),
    (name: 'Tidal Wave', brand: Color(0xFF16EAF9), bg: Color(0xFFEBF8FB)),
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
    final Color brandColor = themeProvider.brandColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Appearance',
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: cs.onSurface,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: tt.titleSmall?.copyWith(
                color: brandColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildThemeToggle(
                    context,
                    'System',
                    ThemeMode.system,
                    themeProvider.themeMode == ThemeMode.system,
                    brandColor,
                    cs,
                  ),
                  _buildThemeToggle(
                    context,
                    'Light',
                    ThemeMode.light,
                    themeProvider.themeMode == ThemeMode.light,
                    brandColor,
                    cs,
                  ),
                  _buildThemeToggle(
                    context,
                    'Dark',
                    ThemeMode.dark,
                    themeProvider.themeMode == ThemeMode.dark,
                    brandColor,
                    cs,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _presets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _buildThemePreset(
                      context,
                      _presets[i].name,
                      _presets[i].brand,
                      _presets[i].bg,
                      themeProvider.brandColor == _presets[i].brand &&
                          themeProvider.bgColor == _presets[i].bg,
                      cs,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildSwitchRow(
              title: 'Dark theme',
              subtitle: 'Uses Material 3 dark colors',
              value: isDarkTheme,
              brandColor: brandColor,
              cs: cs,
              onChanged: (_) => themeProvider.toggleDarkTheme(),
            ),
            const SizedBox(height: 12),
            _buildSwitchRow(
              title: 'Pitch black background',
              subtitle: 'Pure black surface in dark mode',
              value: themeProvider.pureBlackDarkMode,
              brandColor: brandColor,
              cs: cs,
              onChanged: themeProvider.setPureBlackDarkMode,
            ),
            const SizedBox(height: 28),
            Text(
              'Display',
              style: tt.titleSmall?.copyWith(
                color: brandColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            _buildDisplayOption('App language', cs),
            _buildDisplayOption('Tablet UI', cs, subtitle: 'Auto'),
            _buildDisplayOption('Date format', cs),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
    BuildContext context,
    String label,
    ThemeMode mode,
    bool isActive,
    Color brandColor,
    ColorScheme cs,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Expanded(
      child: GestureDetector(
        onTap: () => themeProvider.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? brandColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive) ...[
                Icon(
                  Icons.check_rounded,
                  color: _onBrand(brandColor),
                  size: 16,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _onBrand(brandColor) : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreset(
    BuildContext context,
    String name,
    Color brand,
    Color bg,
    bool isSelected,
    ColorScheme cs,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => themeProvider.setThemeColors(brand, bg),
      child: Column(
        children: [
          AnimatedScale(
            scale: isSelected ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 100,
              height: 160,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: brand.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 60,
                      height: 15,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 50,
                      height: 70,
                      decoration: BoxDecoration(
                        color: brand.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 10,
                          decoration: BoxDecoration(
                            color: brand,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      children: [
                        CircleAvatar(radius: 8, backgroundColor: brand),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color brandColor,
    required ColorScheme cs,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, color: cs.onSurface),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: brandColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDisplayOption(
    String title,
    ColorScheme cs, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: cs.onSurface)),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  static Color _onBrand(Color brand) {
    return brand.computeLuminance() > 0.55
        ? const Color(0xFF141410)
        : Colors.white;
  }
}
