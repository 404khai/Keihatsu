import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/CustomBackButton.dart';
import '../theme_provider.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: themeProvider.effectiveBgColor,
      appBar: AppBar(
        backgroundColor: themeProvider.effectiveBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'About',
          style: GoogleFonts.unbounded(
            textStyle: Theme.of(context).textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) {
          final PackageInfo? info = snapshot.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              children: [
                _AboutHeroCard(version: info?.version ?? '—'),
                const SizedBox(height: 18),
                const _AboutMissionCard(),
                const SizedBox(height: 18),
                _AboutHighlightsCard(accent: colors.primary),
                const SizedBox(height: 18),
                _AboutDetailsCard(
                  version: info?.version ?? '—',
                  buildNumber: info?.buildNumber ?? '—',
                ),
                const SizedBox(height: 18),
                _AboutRepositoryCard(onTap: () => _openRepository(context)),
                const SizedBox(height: 28),
                Text(
                  'Made for readers who always have one more chapter.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '© ${DateTime.now().year} Keihatsu',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openRepository(BuildContext context) async {
    final Uri repository = Uri.parse('https://github.com/404khai/Keihatsu');
    final bool opened = await launchUrl(
      repository,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the Keihatsu repository.'),
        ),
      );
    }
  }
}

class _AboutHeroCard extends StatelessWidget {
  const _AboutHeroCard({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color start = Color.lerp(colors.primary, Colors.black, 0.3)!;
    final Color end = Color.lerp(colors.primary, Colors.black, 0.78)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 126,
            height: 126,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Image.asset('images/keihatsu.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keihatsu',
            style: GoogleFonts.unbounded(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Read beyond the next chapter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'VERSION $version',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutMissionCard extends StatelessWidget {
  const _AboutMissionCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return _AboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A better place to read',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Keihatsu is a manga and manhwa reader built around a calm '
            'library, thoughtful source management, and dependable offline '
            'reading.',
            style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AboutHighlightsCard extends StatelessWidget {
  const _AboutHighlightsCard({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _AboutCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const _AboutHighlightRow(
            icon: Icons.auto_awesome_rounded,
            color: Colors.orange,
            title: 'Made for Flutter',
            subtitle: 'A responsive experience across screen sizes',
          ),
          const _AboutDivider(),
          _AboutHighlightRow(
            icon: Icons.download_for_offline_rounded,
            color: accent,
            title: 'Offline first',
            subtitle: 'Keep downloaded chapters ready wherever you are',
          ),
          const _AboutDivider(),
          const _AboutHighlightRow(
            icon: Icons.shield_rounded,
            color: Colors.blue,
            title: 'Local by default',
            subtitle: 'Your reading experience stays yours',
          ),
        ],
      ),
    );
  }
}

class _AboutHighlightRow extends StatelessWidget {
  const _AboutHighlightRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutDetailsCard extends StatelessWidget {
  const _AboutDetailsCard({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    return _AboutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App details',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _AboutValueRow(label: 'Version', value: version),
          const Divider(height: 25),
          _AboutValueRow(label: 'Build', value: buildNumber),
          const Divider(height: 25),
          const _AboutValueRow(label: 'Platform', value: 'Android'),
          const Divider(height: 25),
          const _AboutValueRow(label: 'Developer', value: '404khai'),
        ],
      ),
    );
  }
}

class _AboutValueRow extends StatelessWidget {
  const _AboutValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AboutRepositoryCard extends StatelessWidget {
  const _AboutRepositoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return _AboutCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.code_rounded, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View the project',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Explore Keihatsu on GitHub',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _AboutDivider extends StatelessWidget {
  const _AboutDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 76),
      child: Divider(height: 1),
    );
  }
}
