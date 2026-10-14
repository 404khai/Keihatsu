import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/components/app_update_prompt.dart';
import 'package:keihatsu/components/menu/app_update_sheet.dart';
import 'package:keihatsu/components/menu/styled_sheet.dart';
import 'package:keihatsu/services/app_update_controller.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'support/fake_app_updater.dart';
import 'support/sheet_test_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSheetTestFonts);
  tearDownAll(clearSheetTestFonts);

  Future<void> openSheet(
    WidgetTester tester,
    AppUpdateController controller, {
    bool dark = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEFEFEF),
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppUpdateSheet.show(
                context,
                controller: controller,
                checkOnOpen: false,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('available sheet downloads, then explains a real restart', (
    tester,
  ) async {
    final updater = FakeAppUpdater()..status = UpdateStatus.outdated;
    final controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => true,
    );
    final download = Completer<void>();
    updater.onDownload = () => download.future;
    await controller.checkForUpdates();
    await openSheet(tester, controller);
    expect(find.text('New update available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    await tester.tap(find.text('Download update'));
    await tester.pump();
    expect(find.text('Downloading update'), findsOneWidget);
    updater.next = const Patch(number: 1);
    download.complete();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
    expect(find.textContaining('Close Keihatsu completely'), findsOneWidget);
    expect(find.text('Restart now'), findsNothing);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('Later closes without starting a download', (tester) async {
    final updater = FakeAppUpdater()..status = UpdateStatus.outdated;
    final controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => true,
    );
    await controller.checkForUpdates();
    await openSheet(tester, controller);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(updater.downloads, 0);
    expect(find.text('New update available'), findsNothing);
    controller.dispose();
  });

  testWidgets('offline sheet offers retry and lets reading continue', (
    tester,
  ) async {
    final updater = FakeAppUpdater();
    final controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => false,
    );
    await controller.checkForUpdates();
    await openSheet(tester, controller);
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(updater.checks, 0);
    controller.dispose();
  });

  testWidgets('small dark screen and large text do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final updater = FakeAppUpdater()..status = UpdateStatus.outdated;
    final controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => true,
    );
    await controller.checkForUpdates();
    await openSheet(tester, controller, dark: true, scale: 2);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Download update'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('existing logout sheet still returns confirm/cancel results', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await StyledSheet.show(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Log out?',
                  message: 'Your downloads stay on this device.',
                  confirmLabel: 'Log out',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  Future<void> pumpHost(
    WidgetTester tester,
    AppUpdateController controller,
    GlobalKey<NavigatorState> key,
    AppUpdateNavigatorObserver observer, {
    String initialRoute = '/library',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [observer],
        initialRoute: initialRoute,
        routes: {
          '/': (_) => const Scaffold(body: Text('Root')),
          '/library': (_) => const Scaffold(body: Text('Library')),
          '/login': (_) => const Scaffold(body: Text('Login')),
        },
        builder: (context, child) => AppUpdatePrompt(
          controller: controller,
          navigatorKey: key,
          observer: observer,
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('automatic ready prompt is deferred past login and shown once', (
    tester,
  ) async {
    final updater = FakeAppUpdater()..next = const Patch(number: 1);
    final controller = AppUpdateController(
      updater: updater,
      hasNetwork: () async => false,
    );
    final key = GlobalKey<NavigatorState>();
    final observer = AppUpdateNavigatorObserver();
    await pumpHost(tester, controller, key, observer, initialRoute: '/login');
    expect(find.text('Update ready'), findsNothing);
    key.currentState!.pushNamed('/library');
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
    expect(updater.checks, 0);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await controller.refreshLocal();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    observer.dispose();
  });

  testWidgets('automatic prompt waits until leaving a reader/detail route', (
    tester,
  ) async {
    final updater = FakeAppUpdater();
    final controller = AppUpdateController(updater: updater);
    final key = GlobalKey<NavigatorState>();
    final observer = AppUpdateNavigatorObserver();
    await pumpHost(tester, controller, key, observer);
    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Reader')),
      ),
    );
    await tester.pumpAndSettle();
    updater.next = const Patch(number: 1);
    await controller.refreshLocal();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsNothing);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    observer.dispose();
  });

  testWidgets('automatic prompt never stacks on an existing sheet', (
    tester,
  ) async {
    final updater = FakeAppUpdater();
    final controller = AppUpdateController(updater: updater);
    final key = GlobalKey<NavigatorState>();
    final observer = AppUpdateNavigatorObserver();
    await pumpHost(tester, controller, key, observer);
    unawaited(
      showModalBottomSheet<void>(
        context: key.currentContext!,
        builder: (_) => const Text('Existing sheet'),
      ),
    );
    await tester.pumpAndSettle();
    updater.next = const Patch(number: 1);
    await controller.refreshLocal();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsNothing);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    observer.dispose();
  });

  testWidgets(
    'automatic prompt waits for foreground and notices a newer patch',
    (tester) async {
      final updater = FakeAppUpdater();
      final controller = AppUpdateController(updater: updater);
      final key = GlobalKey<NavigatorState>();
      final observer = AppUpdateNavigatorObserver();
      await pumpHost(tester, controller, key, observer);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      updater.next = const Patch(number: 1);
      await controller.refreshLocal();
      await tester.pump();
      expect(find.text('Update ready'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Update ready'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      updater.next = const Patch(number: 2);
      await controller.refreshLocal();
      await tester.pumpAndSettle();
      expect(find.text('Update ready'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      observer.dispose();
    },
  );
}
