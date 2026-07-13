import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// Pull-to-refresh wrapper that shows the M3 expressive [KeihatsuLoadingIndicator].
class KeihatsuRefreshIndicator extends StatefulWidget {
  const KeihatsuRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 56,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double displacement;

  @override
  State<KeihatsuRefreshIndicator> createState() =>
      _KeihatsuRefreshIndicatorState();
}

class _KeihatsuRefreshIndicatorState extends State<KeihatsuRefreshIndicator> {
  bool _refreshing = false;
  double _dragOffset = 0;

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
          _dragOffset = 0;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_refreshing) return false;

    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical) {
      if (notification.metrics.pixels <= 0 &&
          notification.scrollDelta != null &&
          notification.scrollDelta! < 0) {
        setState(() {
          _dragOffset =
              (_dragOffset - notification.scrollDelta!).clamp(0.0, 120.0);
        });
      } else if (notification.metrics.pixels > 0 && _dragOffset > 0) {
        setState(() => _dragOffset = 0);
      }
    }

    if (notification is ScrollEndNotification) {
      if (_dragOffset >= widget.displacement * 0.75) {
        _startRefresh();
      } else if (_dragOffset > 0) {
        setState(() => _dragOffset = 0);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double offset = _refreshing ? widget.displacement : _dragOffset;
    final double opacity =
        _refreshing ? 1.0 : (offset / widget.displacement).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (offset > 0)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Center(
                  child: KeihatsuLoadingIndicator(
                    contained: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
