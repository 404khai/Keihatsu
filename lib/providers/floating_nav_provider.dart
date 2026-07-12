import 'package:flutter/material.dart';

/// Tracks expand/collapse of the floating bottom navigation bar based on scroll.
class FloatingNavProvider extends ChangeNotifier {
  bool _expanded = true;

  bool get expanded => _expanded;

  void expand() {
    if (!_expanded) {
      _expanded = true;
      notifyListeners();
    }
  }

  void collapse() {
    if (_expanded) {
      _expanded = false;
      notifyListeners();
    }
  }

  /// Mirrors [FloatingToolbarDefaults.floatingToolbarVerticalNestedScroll]:
  /// scrolling down collapses; scrolling up expands.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final double? delta = notification.scrollDelta;
      if (delta == null || delta == 0) return false;

      if (delta > 0 && notification.metrics.pixels > 24) {
        collapse();
      } else if (delta < 0) {
        expand();
      }
    }
    return false;
  }
}
