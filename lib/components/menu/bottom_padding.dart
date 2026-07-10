import 'package:flutter/material.dart';

class BottomPadding extends StatelessWidget {
  const BottomPadding({super.key});

  static double of(BuildContext context) {
    final double viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    return viewPadding > 0 ? viewPadding : 16;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: of(context));
  }
}
