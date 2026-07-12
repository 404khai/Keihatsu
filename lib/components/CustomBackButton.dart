import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double iconSize;
  final double margin;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.iconSize = 28,
    this.margin = 8,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return GestureDetector(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      child: Container(
        margin: EdgeInsets.all(margin),
        padding: EdgeInsets.all(margin * 0.25),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          color: brandColor,
          size: iconSize,
        ),
      ),
    );
  }
}
