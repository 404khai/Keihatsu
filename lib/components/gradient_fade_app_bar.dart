import 'package:flutter/material.dart';

/// App bar that stays transparent at rest and fades in a top-to-bottom
/// gradient while the screen content scrolls underneath.
class GradientFadeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientFadeAppBar({
    super.key,
    required this.baseColor,
    required this.fadeAmount,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
  });

  final Color baseColor;

  /// 0 = fully transparent, 1 = full gradient from [baseColor] to transparent.
  final double fadeAmount;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final double fade = fadeAmount.clamp(0.0, 1.0);

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title,
      actions: actions,
      bottom: bottom,
      flexibleSpace: fade > 0
          ? IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      baseColor.withValues(alpha: fade),
                      baseColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Tracks vertical scroll offset and reports a normalized fade amount.
class GradientFadeScrollListener extends StatefulWidget {
  const GradientFadeScrollListener({
    super.key,
    required this.child,
    required this.onFadeChanged,
    this.fadeDistance = 10,
  });

  final Widget child;
  final ValueChanged<double> onFadeChanged;
  final double fadeDistance;

  @override
  State<GradientFadeScrollListener> createState() =>
      _GradientFadeScrollListenerState();
}

class _GradientFadeScrollListenerState extends State<GradientFadeScrollListener> {
  double _lastFade = -1;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification &&
        notification is! ScrollMetricsNotification) {
      return false;
    }

    final double fade =
        (notification.metrics.pixels / widget.fadeDistance).clamp(0.0, 1.0);

    if ((fade - _lastFade).abs() > 0.001) {
      _lastFade = fade;
      widget.onFadeChanged(fade);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: widget.child,
    );
  }
}

/// Mixin for screens that need local fade state from [GradientFadeScrollListener].
mixin GradientFadeAppBarMixin<T extends StatefulWidget> on State<T> {
  double appBarFade = 0;

  void updateAppBarFade(double fade) {
    if ((fade - appBarFade).abs() <= 0.001) return;
    setState(() => appBarFade = fade);
  }
}
