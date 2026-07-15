import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/library/filter_tabs.dart';
import 'package:keihatsu/components/notification_pill.dart';
import 'package:keihatsu/data/mock_notifications.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({
    super.key,
    required this.brandColor,
  });

  final Color brandColor;

  static Future<void> show(
    BuildContext context, {
    required Color brandColor,
    required Color bgColor,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: bgColor,
        ),
        child: NotificationsBottomSheet(brandColor: brandColor),
      ),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() =>
      _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  String _selectedFilter = 'all';
  late List<AppNotification> _notifications =
      List<AppNotification>.from(mockNotifications);

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'updates':
        return _notifications
            .where((n) => n.category == NotificationCategory.updates)
            .toList();
      case 'system':
        return _notifications
            .where((n) => n.category == NotificationCategory.system)
            .toList();
      default:
        return _notifications;
    }
  }

  void _markAsRead(String id) {
    final int index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    setState(() {
      _notifications[index] = _notifications[index].copyWith(unread: false);
    });
  }

  void _deleteNotification(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final NotificationPillPalette invertedPalette =
        NotificationPillPalette.fromTheme(themeProvider, cs);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: invertedPalette.background,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: invertedPalette.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Notifications',
                    style: GoogleFonts.unbounded(
                      textStyle: tt.titleMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: FilterTabs(
                  scrollable: false,
                  large: true,
                  height: 48,
                  padding: EdgeInsets.zero,
                  tabs: [
                    FilterTab(
                      value: 'all',
                      label: 'All',
                      accent: invertedPalette.background,
                      onAccent: invertedPalette.text,
                    ),
                    FilterTab(
                      value: 'updates',
                      label: 'Updates',
                      accent: invertedPalette.background,
                      onAccent: invertedPalette.text,
                    ),
                    FilterTab(
                      value: 'system',
                      label: 'System',
                      accent: invertedPalette.background,
                      onAccent: invertedPalette.text,
                    ),
                  ],
                  selected: _selectedFilter,
                  onSelected: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filteredNotifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final AppNotification notification =
                      _filteredNotifications[index];
                  return _NotificationCard(
                    key: ValueKey(notification.id),
                    notification: notification,
                    brandColor: widget.brandColor,
                    onMarkRead: () => _markAsRead(notification.id),
                    onDelete: () => _deleteNotification(notification.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.notification,
    required this.brandColor,
    required this.onMarkRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final Color brandColor;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final double textOpacity = notification.unread ? 1.0 : 0.55;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDelete();
          return true;
        }
        onMarkRead();
        return false;
      },
      onDismissed: (_) => onDelete(),
      background: _SwipeActionBackground(
        alignment: Alignment.centerLeft,
        color: cs.errorContainer,
        icon: Icons.delete_outline_rounded,
        iconColor: cs.onErrorContainer,
        label: 'Delete',
      ),
      secondaryBackground: _SwipeActionBackground(
        alignment: Alignment.centerRight,
        color: cs.primaryContainer,
        icon: Icons.mark_email_read_outlined,
        iconColor: cs.onPrimaryContainer,
        label: 'Mark read',
      ),
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingVisual(notification: notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: textOpacity),
                            ),
                          ),
                        ),
                        if (notification.unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: brandColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: textOpacity),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.timestamp,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(
                          alpha: 0.7 * textOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: iconColor),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double opacity = notification.unread ? 1.0 : 0.55;

    if (notification.thumbnailUrl != null) {
      return Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            notification.thumbnailUrl!,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _IconBadge(
              icon: Icons.image_not_supported_outlined,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: _IconBadge(
        icon: notification.icon ?? Icons.notifications_outlined,
        color: notification.iconColor ?? cs.primary,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
