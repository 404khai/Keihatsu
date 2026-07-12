import 'package:flutter/material.dart';
import 'package:keihatsu/components/AppToast.dart';

/// Standard "not built yet" feedback for stubbed actions.
abstract final class ComingSoon {
  static void show(BuildContext context) {
    AppToast.show(
      context,
      message: 'Coming soon — stay tuned!',
      type: AppToastType.warning,
      icon: Icons.rocket_launch_rounded,
    );
  }
}
