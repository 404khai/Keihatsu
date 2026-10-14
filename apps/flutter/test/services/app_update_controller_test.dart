import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/app_update_controller.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../support/fake_app_updater.dart';

void main() {
  late FakeAppUpdater updater;
  late AppUpdateController controller;

  setUp(() {
    updater = FakeAppUpdater();
    controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => true,
    );
  });
  tearDown(() => controller.dispose());

  test('startup/local probes never check the network or download', () async {
    await controller.refreshLocal();
    expect(updater.checks, 0);
    expect(updater.downloads, 0);
    expect(controller.phase, AppUpdatePhase.idle);
    updater.available = false;
    await controller.refreshLocal();
    expect(controller.phase, AppUpdatePhase.unavailable);
  });

  test(
    'local read failure is quiet and does not interrupt offline use',
    () async {
      updater.readFails = true;
      expect(await controller.refreshLocal(), isFalse);
      expect(controller.phase, AppUpdatePhase.idle);
      expect(updater.checks, 0);
    },
  );

  test('download readiness requires a changed local patch', () async {
    updater.status = UpdateStatus.outdated;
    await controller.checkForUpdates();
    expect(controller.phase, AppUpdatePhase.available);
    await controller
        .download(); // Native automatic download already in progress.
    expect(controller.phase, AppUpdatePhase.downloading);
    expect(controller.readyToken, isNull);
    updater.next = const Patch(number: 2);
    await controller.refreshLocal();
    expect(controller.phase, AppUpdatePhase.ready);
    expect(controller.readyToken, '0:2');
  });

  test('successful download announces next-launch readiness', () async {
    updater.status = UpdateStatus.outdated;
    updater.onDownload = () async => updater.next = const Patch(number: 1);
    await controller.checkForUpdates();
    await controller.download();
    expect(updater.downloads, 1);
    expect(controller.phase, AppUpdatePhase.ready);
  });

  test('a rollback to baseline also needs a restart', () async {
    updater.current = const Patch(number: 3);
    await controller.refreshLocal();
    expect(controller.phase, AppUpdatePhase.ready);
    expect(controller.readyToken, '3:0');
  });

  test('an already downloaded patch is available without internet', () async {
    controller.dispose();
    controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => false,
    );
    updater.next = const Patch(number: 1);
    await controller.checkForUpdates();
    expect(controller.phase, AppUpdatePhase.ready);
    expect(updater.checks, 0);
  });

  test(
    'offline check gives a retry message, without a network request',
    () async {
      controller.dispose();
      controller = AppUpdateController(
        updater: updater,
        hasNetwork: () async => false,
      );
      await controller.checkForUpdates();
      expect(controller.phase, AppUpdatePhase.failed);
      expect(controller.failureMessage, contains("You're offline"));
      expect(updater.checks, 0);
    },
  );

  test('check/download errors do not expose raw exceptions', () async {
    updater.onCheck = () async => throw StateError('token=private-test-value');
    await controller.checkForUpdates();
    expect(controller.phase, AppUpdatePhase.failed);
    expect(controller.failureMessage, isNot(contains('token=')));
    updater.onCheck = null;
    updater.status = UpdateStatus.outdated;
    await controller.checkForUpdates();
    updater.onDownload = () async =>
        throw StateError('token=private-test-value');
    await controller.download();
    expect(controller.phase, AppUpdatePhase.failed);
    expect(controller.failureMessage, isNot(contains('token=')));
  });

  test('duplicate user checks and downloads are serialized', () async {
    final check = Completer<UpdateStatus>();
    updater.onCheck = () => check.future;
    final pendingCheck = controller.checkForUpdates();
    await Future<void>.delayed(Duration.zero);
    await controller.checkForUpdates();
    expect(updater.checks, 1);
    check.complete(UpdateStatus.outdated);
    await pendingCheck;
    final download = Completer<void>();
    updater.onDownload = () => download.future;
    final pendingDownload = controller.download();
    await controller.download();
    expect(updater.downloads, 1);
    updater.next = const Patch(number: 1);
    download.complete();
    await pendingDownload;
    expect(controller.phase, AppUpdatePhase.ready);
  });

  testWidgets(
    'background download waiting is bounded and remains recoverable',
    (tester) async {
      updater.status = UpdateStatus.outdated;
      await controller.checkForUpdates();
      await controller.download();
      await tester.pump(const Duration(minutes: 2));
      expect(controller.phase, AppUpdatePhase.failed);
      updater.next = const Patch(number: 1);
      await controller.refreshLocal();
      expect(controller.phase, AppUpdatePhase.ready);
    },
  );
}
