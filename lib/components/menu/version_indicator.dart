import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionIndicator extends StatefulWidget {
  const VersionIndicator({super.key});

  @override
  State<VersionIndicator> createState() => _VersionIndicatorState();
}

class _VersionIndicatorState extends State<VersionIndicator> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _info = info);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PackageInfo? info = _info;
    if (info == null) return const SizedBox.shrink();

    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Image.asset('images/keihatsu.png', height: 24),
        8.gap,
        Text(
          'Keihatsu v${info.version} (${info.buildNumber})',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            textStyle: tt.labelSmall,
            color: cs.outline,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
