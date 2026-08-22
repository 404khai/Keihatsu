import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';

enum AppToastType { success, error, warning }

class AppToast {
  static OverlayEntry? _currentEntry;

  static void show(
      BuildContext context, {
        required String message,
        AppToastType type = AppToastType.success,
        IconData? icon,
        Duration duration = const Duration(seconds: 3),
      }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppToastOverlay(
        message: message,
        type: type,
        icon: icon,
        duration: duration,
        onRemove: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _AppToastOverlay extends StatefulWidget {
  const _AppToastOverlay({
    required this.message,
    required this.type,
    this.icon,
    required this.duration,
    required this.onRemove,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onRemove;
  final VoidCallback onDismissed;

  @override
  State<_AppToastOverlay> createState() => _AppToastOverlayState();
}

class _AppToastOverlayState extends State<_AppToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _dismissTimer;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _dismissTimer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (_isRemoving) return;
    _isRemoving = true;
    _dismissTimer?.cancel();
    await _controller.reverse();
    widget.onRemove();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brandColor = themeProvider.brandColor;
    final backgroundColor = themeProvider.effectiveBgColor;
    final bool isDarkMode =
        themeProvider.themeMode == ThemeMode.dark ||
            themeProvider.pureBlackDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    final toastColors = _resolveToastColors(widget.type);
    final IconData displayIcon = widget.icon ?? toastColors.icon;

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
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
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        toastColors.fill.withOpacity(isDarkMode ? 0.2 : 0.12),
                        backgroundColor,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: toastColors.accent.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withOpacity(
                            isDarkMode ? 0.22 : 0.14,
                          ),
                          blurRadius: 24,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          displayIcon,
                          color: toastColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: dismiss,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              PhosphorIcons.x(),
                              size: 16,
                              color: textColor.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastColors _resolveToastColors(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return _ToastColors(
          accent: const Color(0xFF24B26B),
          fill: const Color(0xFF24B26B),
          icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        );
      case AppToastType.error:
        return _ToastColors(
          accent: const Color(0xFFE5484D),
          fill: const Color(0xFFE5484D),
          icon: PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        );
      case AppToastType.warning:
        return _ToastColors(
          accent: const Color(0xFFF5A524),
          fill: const Color(0xFFF5A524),
          icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
        );
    }
  }
}

class _ToastColors {
  const _ToastColors({
    required this.accent,
    required this.fill,
    required this.icon,
  });

  final Color accent;
  final Color fill;
  final IconData icon;
}
