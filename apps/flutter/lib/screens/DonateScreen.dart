import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../components/CustomBackButton.dart';

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Donate',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(
                PhosphorIcons.tipJar(PhosphorIconsStyle.fill),
                size: 80,
                color: brandColor,
              ),
              const SizedBox(height: 30),
              Text(
                'Support Keihatsu',
                textAlign: TextAlign.center,
                style: GoogleFonts.denkOne(
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'If you enjoy using Keihatsu, consider supporting our development. Your donations help us keep the servers running and add new features!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _buildDonateOption(
                context,
                "Buy Me a Coffee",
                "A small gesture to keep us caffeinated.",
                PhosphorIcons.coffee(),
                brandColor,
                textColor,
                cardColor,
              ),
              const SizedBox(height: 16),
              _buildDonateOption(
                context,
                "Patreon",
                "Become a monthly supporter for exclusive perks.",
                PhosphorIcons.patreonLogo(),
                brandColor,
                textColor,
                cardColor,
              ),
              const SizedBox(height: 16),
              _buildDonateOption(
                context,
                "PayPal",
                "One-time donation via PayPal.",
                PhosphorIcons.paypalLogo(),
                brandColor,
                textColor,
                cardColor,
              ),
              const SizedBox(height: 16),
              _buildDonateOption(
                context,
                "Cryptocurrency",
                "Support us using Bitcoin or Ethereum.",
                PhosphorIcons.currencyBtc(),
                brandColor,
                textColor,
                cardColor,
              ),
              const SizedBox(height: 60),
              Text(
                'Thank you for your generosity!',
                style: GoogleFonts.delius(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandColor,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonateOption(
    BuildContext context,
    String title,
    String subtitle,
    PhosphorIconData icon,
    Color brandColor,
    Color textColor,
    Color cardColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: brandColor, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          PhosphorIcons.caretRight(),
          color: textColor.withOpacity(0.3),
        ),
        onTap: () {
          // Implement donation logic or open external URL
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thank you! Redirecting to $title...')),
          );
        },
      ),
    );
  }
}
