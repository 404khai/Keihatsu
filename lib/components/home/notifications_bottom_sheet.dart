import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/library/filter_tabs.dart';
import 'package:keihatsu/data/mock_notifications.dart';

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

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'updates':
        return mockNotifications
            .where((n) => n.category == NotificationCategory.updates)
            .toList();
      case 'system':
        return mockNotifications
            .where((n) => n.category == NotificationCategory.system)
            .toList();
      default:
        return mockNotifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                      color: cs.surfaceContainerHigh,
                      shape: CircleBorder(
                        side: BorderSide(color: widget.brandColor, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: widget.brandColor,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: FilterTabs(
                  scrollable: false,
                  height: 44,
                  padding: EdgeInsets.zero,
                  tabs: [
                    FilterTab(
                      value: 'all',
                      label: 'All',
                      accent: cs.surfaceContainerHighest,
                      onAccent: cs.onSurface,
                    ),
                    FilterTab(
                      value: 'updates',
                      label: 'Updates',
                      accent: cs.surfaceContainerHighest,
                      onAccent: cs.onSurface,
                    ),
                    FilterTab(
                      value: 'system',
                      label: 'System',
                      accent: cs.surfaceContainerHighest,
                      onAccent: cs.onSurface,
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
                  return _NotificationCard(
                    notification: _filteredNotifications[index],
                    brandColor: widget.brandColor,
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
    required this.notification,
    required this.brandColor,
  });

  final AppNotification notification;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
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
                            color: cs.onSurface,
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
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.timestamp,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    if (notification.thumbnailUrl != null) {
      return ClipRRect(
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
      );
    }

    return _IconBadge(
      icon: notification.icon ?? Icons.notifications_outlined,
      color: notification.iconColor ?? cs.primary,
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
