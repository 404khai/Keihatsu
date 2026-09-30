import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications_api.dart';
import '../providers/download_provider.dart';

@pragma('vm:entry-point')
Future<void> keihatsuBackgroundMessage(RemoteMessage message) async {
  // Android displays notification payloads in the background. Inbox data is on the server.
}

class PushCoordinator {
  final api = NotificationsApi();
  final local = FlutterLocalNotificationsPlugin();
  final navigatorKey = GlobalKey<NavigatorState>();
  String? _authToken;
  String? _installationId;
  StreamSubscription<String>? _refreshSubscription;
  final Map<String, int> _downloadStatuses = {};

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    FirebaseMessaging.onBackgroundMessage(keihatsuBackgroundMessage);
    await local.initialize(settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (_) => openInbox());
    final android = local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in <AndroidNotificationChannel>[
      const AndroidNotificationChannel('downloads', 'Downloads', importance: Importance.low),
      const AndroidNotificationChannel('incognito', 'Incognito', importance: Importance.min, playSound: false),
      const AndroidNotificationChannel('library_updates', 'Library updates', importance: Importance.defaultImportance),
      const AndroidNotificationChannel('comments_social', 'Comments and social', importance: Importance.defaultImportance),
      const AndroidNotificationChannel('system_announcements', 'System announcements', importance: Importance.defaultImportance),
    ]) { await android?.createNotificationChannel(channel); }
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      final channel = message.data['type'] == 'CHAPTER_UPDATE' ? 'library_updates' :
        (message.data['type'] as String? ?? '').startsWith('COMMENT_') ? 'comments_social' : 'system_announcements';
      local.show(id: message.messageId.hashCode, title: notification.title, body: notification.body,
        notificationDetails: NotificationDetails(android: AndroidNotificationDetails(channel, channel,
          importance: Importance.defaultImportance, groupKey: message.data['groupingKey'] as String?)));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) => openInbox(message.data['notificationId'] as String?));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) WidgetsBinding.instance.addPostFrameCallback((_) => openInbox(initial.data['notificationId'] as String?));
    _refreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) => registerToken(token));
  }

  Future<String> installationId() async {
    if (_installationId != null) return _installationId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('pushInstallationId');
    if (id == null) {
      id = '${DateTime.now().microsecondsSinceEpoch}-${UniqueKey()}';
      await prefs.setString('pushInstallationId', id);
    }
    return _installationId = id;
  }

  Future<void> signedIn(String token) async {
    if (!Platform.isAndroid) return;
    _authToken = token;
    await FirebaseMessaging.instance.requestPermission();
    final pushToken = await FirebaseMessaging.instance.getToken();
    if (pushToken != null) await registerToken(pushToken);
  }

  Future<void> registerToken(String pushToken) async {
    final token = _authToken;
    if (token == null) return;
    final version = (await PackageInfo.fromPlatform()).version;
    await api.register(token, await installationId(), pushToken, version);
  }

  Future<void> signedOut(String? token) async {
    _authToken = null;
    if (token != null && Platform.isAndroid) {
      await api.unregister(token, await installationId());
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  void openInbox([String? notificationId]) {
    navigatorKey.currentState?.pushNamed('/inbox', arguments: notificationId);
  }
  void watchDownloads(DownloadProvider provider) {
    provider.addListener(() => _syncDownloads(provider));
    _syncDownloads(provider);
  }

  void _syncDownloads(DownloadProvider provider) {
    if (!Platform.isAndroid) return;
    final active = provider.queue.where((item) => item.status == 1).toList();
    if (active.isNotEmpty) {
      final percent = (active.map((item) => item.progress).fold<double>(0, (a, b) => a + b) /
        active.length * 100).round();
      local.show(id: 1001, title: 'Downloading ${active.length} chapters', body: '$percent% complete',
        notificationDetails: const NotificationDetails(android: AndroidNotificationDetails(
          'downloads', 'Downloads', importance: Importance.low, ongoing: true, onlyAlertOnce: true,
          showProgress: true, maxProgress: 100)));
    } else { local.cancel(id: 1001); }
    for (final item in provider.queue) {
      final previous = _downloadStatuses[item.chapterId];
      _downloadStatuses[item.chapterId] = item.status;
      if (previous == null || previous == item.status || ![2, 3, 4].contains(item.status)) continue;
      final state = item.status == 2 ? 'completed' : item.status == 3 ? 'failed' : 'paused';
      local.show(id: item.chapterId.hashCode, title: 'Download $state', body: item.chapterName,
        notificationDetails: const NotificationDetails(android: AndroidNotificationDetails(
          'downloads', 'Downloads', importance: Importance.low)));
    }
    if (!provider.isOnline && provider.activeDownloadCount > 0) {
      local.show(id: 1002, title: 'Downloads waiting for a connection', body: 'Downloads resume when online.',
        notificationDetails: const NotificationDetails(android: AndroidNotificationDetails(
          'downloads', 'Downloads', importance: Importance.low, ongoing: true)));
    } else { local.cancel(id: 1002); }
  }

  Future<void> setIncognito(bool enabled) async {
    if (!Platform.isAndroid) return;
    if (!enabled) { await local.cancel(id: 1003); return; }
    await local.show(id: 1003, title: 'Incognito mode is on', body: 'Reading activity stays private on this device.',
      notificationDetails: const NotificationDetails(android: AndroidNotificationDetails(
        'incognito', 'Incognito', importance: Importance.min, ongoing: true, silent: true, onlyAlertOnce: true)));
  }
  Future<void> dispose() async { await _refreshSubscription?.cancel(); }
}
