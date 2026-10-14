import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/app_update_controller.dart';
import 'styled_sheet.dart';

class AppUpdateSheet extends StatelessWidget {
  const AppUpdateSheet({super.key, required this.controller});

  final AppUpdateController controller;

  static Future<void> show(
    BuildContext context, {
    required AppUpdateController controller,
    bool checkOnOpen = true,
  }) {
    if (checkOnOpen) unawaited(controller.checkForUpdates());
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppUpdateSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        final (title, message, label, cancel) = switch (phase) {
          AppUpdatePhase.idle => (
            'App updates',
            'Check for the latest improvements to Keihatsu.',
            'Check for updates',
            'Later',
          ),
          AppUpdatePhase.checking => (
            'Checking for updates',
            'You can keep reading while we look for improvements.',
            'Checking…',
            'Continue reading',
          ),
          AppUpdatePhase.available => (
            'New update available',
            'Get the latest improvements without reinstalling Keihatsu. '
                'They’ll take effect after you close and reopen the app.',
            'Download update',
            'Later',
          ),
          AppUpdatePhase.downloading => (
            'Downloading update',
            'Keep reading while the update downloads. '
                'We’ll let you know when it’s ready.',
            'Continue reading',
            null,
          ),
          AppUpdatePhase.ready => (
            'Update ready',
            'Close Keihatsu completely and reopen it to finish updating. '
                'Your library and downloads stay on this device.',
            'Got it',
            null,
          ),
          AppUpdatePhase.upToDate => (
            'You’re up to date',
            'You’re running the latest available update. Happy reading!',
            'Done',
            null,
          ),
          AppUpdatePhase.unavailable => (
            'Updates unavailable',
            'Install the latest Keihatsu release to enable in-app updates.',
            'Close',
            null,
          ),
          AppUpdatePhase.failed => (
            'Couldn’t finish updating',
            controller.failureMessage ?? 'Keep reading and try again later.',
            'Try again',
            'Later',
          ),
        };
        return StyledSheet(
          icon: phase == AppUpdatePhase.ready
              ? Icons.task_alt_rounded
              : Icons.system_update_rounded,
          title: title,
          message: message,
          confirmLabel: label,
          cancelLabel: cancel,
          confirmEnabled: phase != AppUpdatePhase.checking,
          busy:
              phase == AppUpdatePhase.checking ||
              phase == AppUpdatePhase.downloading,
          onConfirm: switch (phase) {
            AppUpdatePhase.available => () => unawaited(controller.download()),
            AppUpdatePhase.idle || AppUpdatePhase.failed => () => unawaited(
              controller.checkForUpdates(),
            ),
            _ => () => Navigator.of(context).pop(),
          },
        );
      },
    );
  }
}
