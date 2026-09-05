import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:material_shapes/material_shapes.dart';

/// Floating confirmation card — BunPod-style replacement for center dialogs.
/// Resolves to `true` only when confirm is tapped.
class StyledSheet extends StatelessWidget {
  const StyledSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StyledSheet(
          icon: icon,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          destructive: destructive,
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Color heroBackground =
        destructive ? cs.errorContainer : cs.secondaryContainer;
    final Color heroForeground =
        destructive ? cs.onErrorContainer : cs.onSecondaryContainer;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            color: cs.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(52),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: ShapeDecoration(
                        color: heroBackground,
                        shape: MaterialShapeBorder(
                          shape: destructive
                              ? MaterialShapes.sunny
                              : MaterialShapes.cookie7Sided,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: heroForeground,
                      ),
                    ),
                  ),
                  16.gap,
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.unbounded(
                      textStyle: tt.titleLarge,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  16.gap,
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(
                      height: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  24.gap,
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        textStyle: tt.titleMedium,
                        backgroundColor: destructive ? cs.error : null,
                        foregroundColor: destructive ? cs.onError : null,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                  8.gap,
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        textStyle: tt.titleMedium,
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
