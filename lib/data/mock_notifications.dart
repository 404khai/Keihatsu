import 'package:flutter/material.dart';

enum NotificationCategory { updates, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.occurredAt,
    required this.category,
    this.thumbnailUrl,
    this.icon,
    this.iconColor,
    this.unread = false,
  });

  final String id;
  final String title;
  final String description;
  final String timestamp;
  final DateTime occurredAt;
  final NotificationCategory category;
  final String? thumbnailUrl;
  final IconData? icon;
  final Color? iconColor;
  final bool unread;

  AppNotification copyWith({bool? unread}) {
    return AppNotification(
      id: id,
      title: title,
      description: description,
      timestamp: timestamp,
      occurredAt: occurredAt,
      category: category,
      thumbnailUrl: thumbnailUrl,
      icon: icon,
      iconColor: iconColor,
      unread: unread ?? this.unread,
    );
  }
}

DateTime _daysAgo(int days, {int hours = 0, int minutes = 0}) {
  final DateTime now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).subtract(Duration(days: days, hours: hours, minutes: minutes));
}

final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 'ordeal-ch52',
    title: 'Ordeal',
    description: 'Ch 52 Released',
    timestamp: '2m ago',
    occurredAt: _daysAgo(0, minutes: 2),
    category: NotificationCategory.updates,
    thumbnailUrl: 'images/manwha/ordeal.png',
    unread: true,
  ),
  AppNotification(
    id: 'northernblade-ch130',
    title: 'Northern Blade',
    description: 'Ch 130 Released',
    timestamp: '1h ago',
    occurredAt: _daysAgo(0, hours: 1),
    category: NotificationCategory.updates,
    thumbnailUrl: 'images/manwha/northernblade.png',
    unread: true,
  ),
  AppNotification(
    id: 'update-available',
    title: 'Update Available',
    description: 'Keihatsu v1.2.0 is ready to install',
    timestamp: 'Yesterday',
    occurredAt: _daysAgo(1, hours: 3),
    category: NotificationCategory.system,
    icon: Icons.download_rounded,
    iconColor: Color(0xFF4ADE80),
    unread: true,
  ),
  AppNotification(
    id: 'sync-queued',
    title: 'Sync Queued',
    description: '12 chapters from "The Legendary Mechanic"',
    timestamp: 'Yesterday',
    occurredAt: _daysAgo(1, hours: 8),
    category: NotificationCategory.system,
    icon: Icons.cloud_sync_rounded,
    iconColor: Color(0xFF60A5FA),
    unread: true,
  ),
  AppNotification(
    id: 'source-warning',
    title: 'Source Warning',
    description: '"AsuraScans" timeout resolved',
    timestamp: '2d ago',
    occurredAt: _daysAgo(2, hours: 5),
    category: NotificationCategory.system,
    icon: Icons.extension_rounded,
    iconColor: Color(0xFFFB923C),
  ),
];

String notificationDateGroupLabel(DateTime occurredAt) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(
    occurredAt.year,
    occurredAt.month,
    occurredAt.day,
  );
  final int diff = today.difference(day).inDays;

  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '$diff days ago';
}

int notificationDateGroupSortKey(String label) {
  if (label == 'Today') return 0;
  if (label == 'Yesterday') return 1;
  final RegExp match = RegExp(r'^(\d+) days ago$');
  final Match? result = match.firstMatch(label);
  if (result != null) return int.parse(result.group(1)!);
  return 999;
}

List<MapEntry<String, List<AppNotification>>> groupNotificationsByDate(
  List<AppNotification> notifications,
) {
  final Map<String, List<AppNotification>> grouped =
      <String, List<AppNotification>>{};

  for (final AppNotification notification in notifications) {
    final String label = notificationDateGroupLabel(notification.occurredAt);
    grouped.putIfAbsent(label, () => <AppNotification>[]).add(notification);
  }

  for (final List<AppNotification> items in grouped.values) {
    items.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  final List<MapEntry<String, List<AppNotification>>> entries =
      grouped.entries.toList()
        ..sort(
          (a, b) => notificationDateGroupSortKey(a.key)
              .compareTo(notificationDateGroupSortKey(b.key)),
        );

  return entries;
}
