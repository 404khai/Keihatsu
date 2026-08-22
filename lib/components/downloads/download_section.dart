import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';

class DownloadSection extends StatelessWidget {
  const DownloadSection({
    super.key,
    required this.label,
    this.image,
    this.meta,
    this.action,
    required this.child,
  });

  final String label;
  final String? image;
  final String? meta;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              if (image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    image!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Icon(
                      Icons.extension_outlined,
                      size: 22,
                      color: cs.primary,
                    ),
                  ),
                ),
                10.gap,
              ],
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.unbounded(
                    textStyle: tt.labelLarge,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: cs.primary,
                  ),
                ),
              ),
              if (action != null)
                action!
              else if (meta != null)
                Text(
                  meta!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
