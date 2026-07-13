import 'package:flutter/material.dart';

enum NotificationCategory { updates, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
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
  final NotificationCategory category;
  final String? thumbnailUrl;
  final IconData? icon;
  final Color? iconColor;
  final bool unread;
}

final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 'ordeal-ch52',
    title: 'Ordeal',
    description: 'Ch 52 Released',
    timestamp: '2m ago',
    category: NotificationCategory.updates,
    thumbnailUrl: 'images/manwha/ordeal.png',
    unread: true,
  ),
  AppNotification(
    id: 'northernblade-ch130',
    title: 'Northern Blade',
    description: 'Ch 130 Released',
    timestamp: '1h ago',
    category: NotificationCategory.updates,
    thumbnailUrl: 'images/manwha/northernblade.png',
    unread: true,
  ),
  AppNotification(
    id: 'update-available',
    title: 'Update Available',
    description: 'Keihatsu v1.2.0 is ready to install',
    timestamp: 'Yesterday',
    category: NotificationCategory.system,
    icon: Icons.download_rounded,
    iconColor: Color(0xFF4ADE80),
  ),
  AppNotification(
    id: 'sync-queued',
    title: 'Sync Queued',
    description: '12 chapters from "The Legendary Mechanic"',
    timestamp: 'Yesterday',
    category: NotificationCategory.system,
    icon: Icons.cloud_sync_rounded,
    iconColor: Color(0xFF60A5FA),
  ),
  AppNotification(
    id: 'source-warning',
    title: 'Source Warning',
    description: '"AsuraScans" timeout resolved',
    timestamp: '2d ago',
    category: NotificationCategory.system,
    icon: Icons.extension_rounded,
    iconColor: Color(0xFFFB923C),
  ),
];
