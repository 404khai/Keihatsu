import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/floating_nav_provider.dart';

/// Wrap scrollable screen bodies so the floating nav expands/collapses on scroll.
class FloatingNavScrollScope extends StatelessWidget {
  const FloatingNavScrollScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: context.read<FloatingNavProvider>().handleScrollNotification,
      child: child,
    );
  }
}
