import 'package:flutter/material.dart';
import 'package:keihatsu/components/notification_pill.dart';

/// Standard "not built yet" feedback for stubbed actions.
abstract final class ComingSoon {
  static void show(BuildContext context) {
    NotificationPill.show(
      context,
      message: 'Coming soon — stay tuned!',
      icon: Icons.rocket_launch_rounded,
    );
  }
}
