import 'package:flutter/material.dart';

/// Tracks expand/collapse of the floating bottom navigation bar based on scroll.
class FloatingNavProvider extends ChangeNotifier {
  bool _expanded = true;
  bool _userVerticalScroll = false;

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
  ///
  /// Ignores horizontal scroll (carousels, tab swipes, filter tabs) and
  /// programmatic scroll animations that are not driven by a user drag.
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      _userVerticalScroll = notification.dragDetails != null;
      return false;
    }

    if (notification is ScrollEndNotification) {
      _userVerticalScroll = false;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (!_userVerticalScroll) return false;

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
