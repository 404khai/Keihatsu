import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_update_controller.dart';
import 'menu/app_update_sheet.dart';

/// Prompts only on named top-level pages, never over a reader, sign-in flow,
/// unnamed detail page or another modal sheet.
class AppUpdateNavigatorObserver extends NavigatorObserver with ChangeNotifier {
  Route<dynamic>? _top;

  bool get canPrompt =>
      _top is PageRoute &&
      const {
        '/library',
        '/home',
        '/history',
        '/profile',
        '/extensions',
        '/settings',
      }.contains(_top?.settings.name);

  void _changed(Route<dynamic>? route) {
    _top = route;
    notifyListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _changed(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (identical(_top, route)) _changed(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (identical(_top, oldRoute)) _changed(newRoute);
  }
}

class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    super.key,
    required this.controller,
    required this.observer,
    required this.navigatorKey,
    required this.child,
  });

  final AppUpdateController controller;
  final AppUpdateNavigatorObserver observer;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends State<AppUpdatePrompt>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _sheetOpen = false;
  bool _scheduled = false;
  String? _promptedToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_considerPrompt);
    widget.observer.addListener(_considerPrompt);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_foreground) _startLocalProbes();
  }

  void _startLocalProbes() {
    _timer?.cancel();
    unawaited(widget.controller.refreshLocal());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(widget.controller.refreshLocal());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_foreground) {
      _startLocalProbes();
      _considerPrompt();
    }
  }

  void _considerPrompt() {
    if (!mounted || !_foreground || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted ||
          !_foreground ||
          _sheetOpen ||
          !widget.observer.canPrompt ||
          widget.controller.phase != AppUpdatePhase.ready) {
        return;
      }
      final token = widget.controller.readyToken;
      final context = widget.navigatorKey.currentContext;
      if (token == null || token == _promptedToken || context == null) return;
      _promptedToken = token;
      _sheetOpen = true;
      unawaited(
        AppUpdateSheet.show(
          context,
          controller: widget.controller,
          checkOnOpen: false,
        ).whenComplete(() => _sheetOpen = false),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_considerPrompt);
    widget.observer.removeListener(_considerPrompt);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
