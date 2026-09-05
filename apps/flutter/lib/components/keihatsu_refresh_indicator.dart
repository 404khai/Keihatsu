import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_provider.dart';
import 'loading_indicator.dart';

/// Pull-to-refresh wrapper that shows the M3 expressive [KeihatsuLoadingIndicator].
///
/// Scroll handling mirrors Flutter's [RefreshIndicator] so overscroll is tracked
/// reliably on both iOS and Android.
class KeihatsuRefreshIndicator extends StatefulWidget {
  const KeihatsuRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 40,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double displacement;
  final double edgeOffset;

  @override
  State<KeihatsuRefreshIndicator> createState() =>
      _KeihatsuRefreshIndicatorState();
}

class _KeihatsuRefreshIndicatorState extends State<KeihatsuRefreshIndicator> {
  static const double _kDragContainerExtentPercentage = 0.25;

  bool _refreshing = false;
  double? _dragOffset;

  Future<void> _startRefresh() async {
    setState(() {
      _refreshing = true;
      _dragOffset = widget.displacement;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _dragOffset = null;
        });
      }
    }
  }

  bool _shouldStart(ScrollNotification notification) {
    return notification is ScrollStartNotification &&
        notification.dragDetails != null &&
        notification.metrics.extentBefore == 0.0;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_refreshing) return false;

    if (_dragOffset == null) {
      if (_shouldStart(notification)) {
        setState(() => _dragOffset = 0);
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final double? delta = notification.scrollDelta;
      if (delta != null) {
        if (notification.metrics.axisDirection == AxisDirection.down) {
          setState(() => _dragOffset = _dragOffset! - delta);
        } else if (notification.metrics.axisDirection == AxisDirection.up) {
          setState(() => _dragOffset = _dragOffset! + delta);
        }
      }

      if (_dragOffset! >= _armedOffset(notification.metrics.viewportDimension) &&
          notification.dragDetails == null) {
        _startRefresh();
      }
    } else if (notification is OverscrollNotification) {
      if (notification.metrics.axisDirection == AxisDirection.down) {
        setState(() => _dragOffset = _dragOffset! - notification.overscroll);
      } else if (notification.metrics.axisDirection == AxisDirection.up) {
        setState(() => _dragOffset = _dragOffset! + notification.overscroll);
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragOffset! >= _armedOffset(notification.metrics.viewportDimension)) {
        _startRefresh();
      } else {
        setState(() => _dragOffset = null);
      }
    }

    return false;
  }

  bool _handleOverscrollIndicator(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) return false;
    if (_dragOffset != null) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  double _armedOffset(double viewportDimension) {
    return viewportDimension * _kDragContainerExtentPercentage * 0.75;
  }

  double _dragScale(double viewportDimension) {
    if (_dragOffset == null) return 0;
    return (_dragOffset! /
            (viewportDimension * _kDragContainerExtentPercentage))
        .clamp(0.0, 1.0);
  }

  Color _indicatorColor(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color brand = context.read<ThemeProvider>().brandColor;
    if (brand.computeLuminance() > 0.65) {
      return cs.onSurface;
    }
    return brand;
  }

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double topInset = MediaQuery.paddingOf(context).top + widget.edgeOffset;
    final bool showIndicator = _refreshing || (_dragOffset ?? 0) > 0;
    final double scale = _refreshing ? 1.0 : _dragScale(viewportHeight);
    final double opacity = _refreshing ? 1.0 : scale.clamp(0.35, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: _handleOverscrollIndicator,
            child: widget.child,
          ),
        ),
        if (showIndicator)
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: math.max(scale, 0.5),
                  child: Padding(
                    padding: EdgeInsets.only(top: widget.displacement),
                    child: Center(
                      child: KeihatsuLoadingIndicator(
                        contained: true,
                        color: _indicatorColor(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
