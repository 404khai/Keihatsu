import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../components/CustomBackButton.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'About',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            children: [
              // App Logo
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      'images/keihatsu.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // App Name & Version
              Text(
                'Keihatsu',
                style: GoogleFonts.hennyPenny(
                  textStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Built By
              Text(
                'Built by',
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'GRVT8 Labs',
                style: GoogleFonts.delius(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Social Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(PhosphorIcons.globe(), () {}),
                  _buildSocialIcon(PhosphorIcons.xLogo(), () {}),
                  _buildSocialIcon(PhosphorIcons.githubLogo(), () {}),
                  _buildSocialIcon(PhosphorIcons.discordLogo(), () {}),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Footer text
              Text(
                '© 2025 Keihatsu. All rights reserved.',
                style: TextStyle(
                  color: textColor.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(PhosphorIconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          icon,
          size: 28,
          color: Colors.grey.withOpacity(0.6),
        ),
      ),
    );
  }
}
