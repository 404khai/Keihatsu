import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';

/// Colors for notification pills and related inverted-surface UI.
class NotificationPillPalette {
  const NotificationPillPalette({
    required this.background,
    required this.iconBackground,
    required this.iconForeground,
    required this.text,
    required this.pointer,
  });

  final Color background;
  final Color iconBackground;
  final Color iconForeground;
  final Color text;
  final Color pointer;

  static NotificationPillPalette fromTheme(
    ThemeProvider themeProvider,
    ColorScheme cs,
  ) {
    final Color brand = themeProvider.brandColor;
    final Color invertedBackground = _invertedPageBackground(themeProvider);
    final Color invertedOnSurface = _invertedPageOnSurface(themeProvider);

    return NotificationPillPalette(
      background: invertedBackground,
      iconBackground: brand,
      iconForeground: _onBadge(brand),
      text: invertedOnSurface,
      pointer: brand,
    );
  }

  static Color _invertedPageBackground(ThemeProvider themeProvider) {
    if (themeProvider.isDarkTheme) {
      return themeProvider.bgColor;
    }

    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: themeProvider.brandColor,
      primary: themeProvider.brandColor,
      brightness: Brightness.dark,
    );
    return darkScheme.surface;
  }

  static Color _invertedPageOnSurface(ThemeProvider themeProvider) {
    final ColorScheme invertedScheme = ColorScheme.fromSeed(
      seedColor: themeProvider.brandColor,
      primary: themeProvider.brandColor,
      brightness:
          themeProvider.isDarkTheme ? Brightness.light : Brightness.dark,
    );
    return invertedScheme.onSurface;
  }

  static Color _onBadge(Color badge) {
    return badge.computeLuminance() > 0.55
        ? const Color(0xFF141410)
        : Colors.white;
  }
}

/// Stadium-shaped notification pill with a leading D-shaped icon badge.
class NotificationPill extends StatelessWidget {
  const NotificationPill({
    super.key,
    required this.message,
    this.icon = Icons.rocket_launch_rounded,
    this.showPointer = false,
    this.palette,
  });

  static const double _pillInset = 6;
  static const double _badgeSize = 36;
  static const double _stackPeekOffset = 58;

  final String message;
  final IconData icon;
  final bool showPointer;
  final NotificationPillPalette? palette;

  static OverlayEntry? _stackEntry;
  static _PersistentPillData? _persistentPill;
  static _TransientPillData? _transientPill;
  static Timer? _transientTimer;
  static VoidCallback? _rebuildStack;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.rocket_launch_rounded,
    bool showPointer = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    _ensureStack(context);
    _transientTimer?.cancel();
    _transientPill = _TransientPillData(
      message: message,
      icon: icon,
      showPointer: showPointer,
    );
    _rebuildStack?.call();
    _transientTimer = Timer(duration, () {
      _transientPill = null;
      _rebuildStack?.call();
      _maybeRemoveStack();
    });
  }

  static void showPersistent(
    BuildContext context, {
    required String id,
    required String message,
    IconData icon = Icons.theater_comedy,
  }) {
    _ensureStack(context);
    _persistentPill = _PersistentPillData(
      id: id,
      message: message,
      icon: icon,
    );
    _rebuildStack?.call();
  }

  static void hidePersistent(String id) {
    if (_persistentPill?.id != id) return;
    _persistentPill = null;
    _rebuildStack?.call();
    _maybeRemoveStack();
  }

  static void _ensureStack(BuildContext context) {
    if (_stackEntry != null) return;

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _NotificationPillStack(
        onRebuild: () => entry.markNeedsBuild(),
        onRegisterRebuild: (callback) => _rebuildStack = callback,
      ),
    );
    _stackEntry = entry;
    overlay.insert(entry);
  }

  static void _maybeRemoveStack() {
    if (_persistentPill != null || _transientPill != null) return;
    _stackEntry?.remove();
    _stackEntry = null;
    _rebuildStack = null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final NotificationPillPalette resolvedPalette =
        palette ?? NotificationPillPalette.fromTheme(themeProvider, cs);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: resolvedPalette.background,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkTheme ? 0.35 : 0.12,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(_pillInset),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBadge(
                  icon: icon,
                  palette: resolvedPalette,
                  size: _badgeSize,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: resolvedPalette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showPointer)
          Positioned(
            bottom: -7,
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _PillPointerPainter(color: resolvedPalette.pointer),
            ),
          ),
      ],
    );
  }
}

class _PersistentPillData {
  const _PersistentPillData({
    required this.id,
    required this.message,
    required this.icon,
  });

  final String id;
  final String message;
  final IconData icon;
}

class _TransientPillData {
  const _TransientPillData({
    required this.message,
    required this.icon,
    required this.showPointer,
  });

  final String message;
  final IconData icon;
  final bool showPointer;
}

class _NotificationPillStack extends StatefulWidget {
  const _NotificationPillStack({
    required this.onRebuild,
    required this.onRegisterRebuild,
  });

  final VoidCallback onRebuild;
  final ValueChanged<VoidCallback> onRegisterRebuild;

  @override
  State<_NotificationPillStack> createState() => _NotificationPillStackState();
}

class _NotificationPillStackState extends State<_NotificationPillStack> {
  @override
  void initState() {
    super.initState();
    widget.onRegisterRebuild(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final _PersistentPillData? persistent = NotificationPill._persistentPill;
    final _TransientPillData? transient = NotificationPill._transientPill;
    final bool stacked = persistent != null && transient != null;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (persistent != null)
                Padding(
                  padding: EdgeInsets.only(top: stacked ? NotificationPill._stackPeekOffset : 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: stacked ? 0.92 : 1,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      scale: stacked ? 0.96 : 1,
                      child: NotificationPill(
                        message: persistent.message,
                        icon: persistent.icon,
                      ),
                    ),
                  ),
                ),
              if (transient != null)
                _TransientPillOverlay(
                  message: transient.message,
                  icon: transient.icon,
                  showPointer: transient.showPointer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.palette,
    required this.size,
  });

  final IconData icon;
  final NotificationPillPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.iconBackground,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(size / 2),
          right: Radius.circular(size * 0.32),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: palette.iconForeground, size: size * 0.55),
    );
  }
}

class _PillPointerPainter extends CustomPainter {
  const _PillPointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PillPointerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TransientPillOverlay extends StatefulWidget {
  const _TransientPillOverlay({
    required this.message,
    required this.icon,
    required this.showPointer,
  });

  final String message;
  final IconData icon;
  final bool showPointer;

  @override
  State<_TransientPillOverlay> createState() => _TransientPillOverlayState();
}

class _TransientPillOverlayState extends State<_TransientPillOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: NotificationPill(
            message: widget.message,
            icon: widget.icon,
            showPointer: widget.showPointer,
          ),
        ),
      ),
    );
  }
}
