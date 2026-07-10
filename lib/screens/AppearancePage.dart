import 'package:flutter/material.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme
        ? Colors.black
        : themeProvider.bgColor;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color textColor = isDarkTheme ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Appearance',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: TextStyle(color: brandColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  _buildThemeToggle(
                    context,
                    'System',
                    ThemeMode.system,
                    themeProvider.themeMode == ThemeMode.system,
                    brandColor,
                    textColor,
                  ),
                  _buildThemeToggle(
                    context,
                    'Light',
                    ThemeMode.light,
                    themeProvider.themeMode == ThemeMode.light,
                    brandColor,
                    textColor,
                  ),
                  _buildThemeToggle(
                    context,
                    'Dark',
                    ThemeMode.dark,
                    themeProvider.themeMode == ThemeMode.dark,
                    brandColor,
                    textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildThemePreset(
                    context,
                    'Default',
                    Colors.black,
                    Colors.white,
                    themeProvider.brandColor == Colors.black &&
                        themeProvider.bgColor == Colors.white,
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Rose Blush',
                    ThemeProvider.roseBlushBrand,
                    ThemeProvider.roseBlushBg,
                    themeProvider.isRoseBlush,
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Sunrise Gold',
                    ThemeProvider.sunriseGoldBrand,
                    ThemeProvider.sunriseGoldBg,
                    themeProvider.isSunriseGold,
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Carrot Orange',
                    const Color(0xFFF97316),
                    const Color(0xFFFFEDD5),
                    themeProvider.brandColor == const Color(0xFFF97316),
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Green Apple',
                    const Color(0xFF0DB14C),
                    const Color(0xFFE8F5E9),
                    themeProvider.brandColor == const Color(0xFF0DB14C),
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Lavender',
                    const Color(0xFF9061F9),
                    const Color(0xFFF3E8FF),
                    themeProvider.brandColor == const Color(0xFF9061F9),
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Midnight Dusk',
                    const Color(0xFFE02424),
                    const Color(0xFFFDE8E8),
                    themeProvider.brandColor == const Color(0xFFE02424),
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Cool Mint',
                    const Color(0xFFB9F916),
                    const Color(0xFFF1FBEB),
                    themeProvider.brandColor == const Color(0xFFB9F916),
                    textColor,
                  ),
                  const SizedBox(width: 15),
                  _buildThemePreset(
                    context,
                    'Tidal Wave',
                    const Color(0xFF16EAF9),
                    const Color(0xFFEBF8FB),
                    themeProvider.brandColor == const Color(0xFF16EAF9),
                    textColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark theme',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    Text(
                      'Uses Material 3 dark colors',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDarkTheme,
                  activeThumbColor: brandColor,
                  onChanged: (_) => themeProvider.toggleDarkTheme(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pitch black background',
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                    Text(
                      'Pure black surface in dark mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: themeProvider.pureBlackDarkMode,
                  activeThumbColor: brandColor,
                  onChanged: themeProvider.setPureBlackDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Display',
              style: TextStyle(color: brandColor, fontWeight: FontWeight.bold),
            ),
            _buildDisplayOption('App language', textColor),
            _buildDisplayOption('Tablet UI', textColor, subtitle: 'Auto'),
            _buildDisplayOption('Date format', textColor),
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
    Color textColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Expanded(
      child: GestureDetector(
        onTap: () => themeProvider.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? brandColor.withOpacity(0.8) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : textColor,
                  fontWeight: FontWeight.bold,
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
    Color textColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => themeProvider.setThemeColors(brand, bg),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 160,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: brand, width: 3)
                  : Border.all(color: Colors.black12),
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
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: brand.withOpacity(0.2),
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
                            color: Colors.black12,
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
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayOption(String title, Color textColor, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: textColor)),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
            ),
        ],
      ),
    );
  }
}
