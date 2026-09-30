import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/providers/notification_unread_provider.dart';
import 'package:keihatsu/services/notifications_api.dart';

class CountApi extends NotificationsApi {
  final requests = <Completer<int>>[];
  @override
  Future<int> unreadCount(String token) {
    final request = Completer<int>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads at login and shares optimistic counts and rollback', () async {
    final api = CountApi();
    final store = NotificationUnreadProvider(api: api);
    addTearDown(store.dispose);
    store.setSession('account');
    api.requests.single.complete(3);
    await Future<void>.delayed(Duration.zero);
    expect(store.count, 3);
    store.adjust(-1);
    expect(store.count, 2);
    store.adjust(1);
    expect(store.count, 3);
    store.setCount(0);
    expect(store.count, 0);
  });

  test('does not restore a previous account count after logout', () async {
    final api = CountApi();
    final store = NotificationUnreadProvider(api: api);
    addTearDown(store.dispose);
    store.setSession('old-account');
    store.setSession(null);
    api.requests.single.complete(8);
    await Future<void>.delayed(Duration.zero);
    expect(store.count, 0);
  });

  test(
    'ignores a stale count while an optimistic mutation is pending',
    () async {
      final api = CountApi();
      final store = NotificationUnreadProvider(api: api);
      addTearDown(store.dispose);
      store.setSession('account');
      store.setCount(2);
      api.requests.single.complete(3);
      await Future<void>.delayed(Duration.zero);
      expect(store.count, 2);
    },
  );

  test('keeps last known count offline and refreshes on resume', () async {
    final api = CountApi();
    final store = NotificationUnreadProvider(api: api);
    addTearDown(store.dispose);
    store.setSession('account');
    api.requests.single.complete(4);
    await Future<void>.delayed(Duration.zero);
    final refresh = store.refresh();
    api.requests.last.completeError(Exception('offline'));
    await refresh;
    expect(store.count, 4);
    store.didChangeAppLifecycleState(AppLifecycleState.paused);
    store.didChangeAppLifecycleState(AppLifecycleState.resumed);
    api.requests.last.complete(1);
    await Future<void>.delayed(Duration.zero);
    expect(store.count, 1);
  });
}
