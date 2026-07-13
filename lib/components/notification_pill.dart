import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';

/// Stadium-shaped notification pill with a leading icon badge.
///
/// Dark theme: charcoal body, mustard icon tile, dark rocket.
/// Light theme: cream body, olive icon disc, white rocket.
class NotificationPill extends StatelessWidget {
  const NotificationPill({
    super.key,
    required this.message,
    this.icon = Icons.rocket_launch_rounded,
    this.showPointer = false,
  });

  final String message;
  final IconData icon;
  final bool showPointer;

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.rocket_launch_rounded,
    bool showPointer = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _NotificationPillOverlay(
        message: message,
        icon: icon,
        showPointer: showPointer,
        duration: duration,
        onRemove: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkTheme;
    final _PillPalette palette = _PillPalette.forTheme(isDark);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(
                icon: icon,
                palette: palette,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 20, 14),
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showPointer)
          Positioned(
            bottom: -7,
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _PillPointerPainter(color: palette.pointer),
            ),
          ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.palette,
    required this.isDark,
  });

  final IconData icon;
  final _PillPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.fromLTRB(6, 6, 0, 6),
        decoration: BoxDecoration(
          color: palette.iconBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: palette.iconForeground, size: 22),
      );
    }

    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: palette.iconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: palette.iconForeground, size: 22),
    );
  }
}

class _PillPalette {
  const _PillPalette({
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

  static _PillPalette forTheme(bool isDark) {
    if (isDark) {
      return const _PillPalette(
        background: Color(0xFF1E1E1A),
        iconBackground: Color(0xFFC4C878),
        iconForeground: Color(0xFF141410),
        text: Color(0xFFF3F3EE),
        pointer: Color(0xFF6D701F),
      );
    }

    return const _PillPalette(
      background: Color(0xFFF2F1E6),
      iconBackground: Color(0xFF6D701F),
      iconForeground: Colors.white,
      text: Color(0xFF2A2824),
      pointer: Color(0xFF6D701F),
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

class _NotificationPillOverlay extends StatefulWidget {
  const _NotificationPillOverlay({
    required this.message,
    required this.icon,
    required this.showPointer,
    required this.duration,
    required this.onRemove,
  });

  final String message;
  final IconData icon;
  final bool showPointer;
  final Duration duration;
  final VoidCallback onRemove;

  @override
  State<_NotificationPillOverlay> createState() =>
      _NotificationPillOverlayState();
}

class _NotificationPillOverlayState extends State<_NotificationPillOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;

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
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: FadeTransition(
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
          ),
        ),
      ),
    );
  }
}
