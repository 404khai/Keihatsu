import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/notifications_api.dart';

/// Account-wide Inbox count, independent of whether the Inbox is open.
class NotificationUnreadProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationUnreadProvider({
    NotificationsApi? api,
    this.pollInterval = const Duration(seconds: 30),
  }) : api = api ?? NotificationsApi() {
    WidgetsBinding.instance.addObserver(this);
  }

  final NotificationsApi api;
  final Duration pollInterval;
  String? _token;
  Timer? _timer;
  int _revision = 0;
  int _count = 0;
  int get count => _count;

  void setSession(String? token) {
    if (_token == token) return;
    _token = token;
    _revision++;
    setCount(0);
    _timer?.cancel();
    if (token != null) {
      unawaited(refresh());
      _startPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    if (_token != null) {
      _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    }
  }

  Future<void> refresh() async {
    final token = _token;
    if (token == null) return;
    final revision = ++_revision;
    try {
      final value = await api.unreadCount(token);
      if (_token == token && _revision == revision) setCount(value);
    } catch (_) {
      // Retain the last known count while offline.
    }
  }

  void setCount(int value) {
    _revision++;
    final next = value < 0 ? 0 : value;
    if (next == _count) return;
    _count = next;
    notifyListeners();
  }

  void adjust(int delta) => setCount(_count + delta);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
      _startPolling();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _token = null;
    _revision++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
