import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/library/filter_tabs.dart';
import 'package:keihatsu/components/menu/menu_extensions.dart';
import 'package:keihatsu/components/menu/menu_section.dart';
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

  List<MapEntry<String, List<AppNotification>>> get _groupedNotifications =>
      groupNotificationsByDate(_filteredNotifications);

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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Container(
                padding: const EdgeInsets.only(left: 5, right: 5),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(99),
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
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final MapEntry<String, List<AppNotification>> group
                      in _groupedNotifications) ...[
                    _NotificationDateGroup(
                      label: group.key,
                      notifications: group.value,
                      brandColor: widget.brandColor,
                      onMarkRead: _markAsRead,
                      onDelete: _deleteNotification,
                    ),
                    24.gap,
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationDateGroup extends StatelessWidget {
  const _NotificationDateGroup({
    required this.label,
    required this.notifications,
    required this.brandColor,
    required this.onMarkRead,
    required this.onDelete,
  });

  final String label;
  final List<AppNotification> notifications;
  final Color brandColor;
  final ValueChanged<String> onMarkRead;
  final ValueChanged<String> onDelete;

  BorderRadius _radiusFor(int index) {
    const Radius outer = Radius.circular(MenuSection.outerRadius);
    const Radius inner = Radius.circular(MenuSection.innerRadius);

    return BorderRadius.vertical(
      top: index == 0 ? outer : inner,
      bottom: index == notifications.length - 1 ? outer : inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            label,
            style: GoogleFonts.unbounded(
              textStyle: tt.labelLarge,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: cs.primary,
            ),
          ),
        ),
        for (int i = 0; i < notifications.length; i++) ...[
          if (i > 0) MenuSection.tileGap.gap,
          _ElasticNotificationTile(
            key: ValueKey(notifications[i].id),
            notification: notifications[i],
            brandColor: brandColor,
            borderRadius: _radiusFor(i),
            onMarkRead: () => onMarkRead(notifications[i].id),
            onDelete: () => onDelete(notifications[i].id),
          ),
        ],
      ],
    );
  }
}

class _ElasticNotificationTile extends StatefulWidget {
  const _ElasticNotificationTile({
    super.key,
    required this.notification,
    required this.brandColor,
    required this.borderRadius,
    required this.onMarkRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final Color brandColor;
  final BorderRadius borderRadius;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  State<_ElasticNotificationTile> createState() =>
      _ElasticNotificationTileState();
}

class _ElasticNotificationTileState extends State<_ElasticNotificationTile>
    with SingleTickerProviderStateMixin {
  static const double _tileHeight = 72;
  static const double _actionThreshold = 76;
  static const double _maxDrag = 132;
  static const double _anchorSize = 56;

  late final AnimationController _snapController;
  Animation<double> _snapAnimation = const AlwaysStoppedAnimation<double>(0);

  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (!mounted) return;
        setState(() => _dragOffset = _snapAnimation.value);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutCubic,
    ));
    _snapController
      ..value = 0
      ..forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _snapController.stop();
    setState(() {
      _dragOffset =
          (_dragOffset + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset >= _actionThreshold) {
      widget.onDelete();
      return;
    }
    if (_dragOffset <= -_actionThreshold) {
      widget.onMarkRead();
      _animateTo(0);
      return;
    }
    _animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppNotification notification = widget.notification;
    final double textOpacity = notification.unread ? 1.0 : 0.55;
    final Color titleColor = cs.onSurface.withValues(alpha: textOpacity);
    final Color bodyColor = cs.onSurfaceVariant.withValues(alpha: textOpacity);

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: _tileHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (_dragOffset > 0)
              _ElasticSwipeReveal(
                extent: _dragOffset,
                fromLeft: true,
                height: _tileHeight,
                anchorSize: _anchorSize,
                color: cs.errorContainer,
                icon: Icons.delete_outline_rounded,
                iconColor: cs.onErrorContainer,
              ),
            if (_dragOffset < 0)
              _ElasticSwipeReveal(
                extent: -_dragOffset,
                fromLeft: false,
                height: _tileHeight,
                anchorSize: _anchorSize,
                color: const Color(0xFFCDEA91),
                icon: Icons.mark_email_read_outlined,
                iconColor: const Color(0xFF1A1A14),
              ),
            GestureDetector(
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Material(
                  color: cs.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _NotificationLeading(
                          notification: notification,
                          opacity: textOpacity,
                        ),
                        16.gap,
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      notification.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodyLarge?.copyWith(
                                        color: titleColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (notification.unread) ...[
                                    6.gap,
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: widget.brandColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              2.gap,
                              Text(
                                notification.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodyMedium?.copyWith(color: bodyColor),
                              ),
                            ],
                          ),
                        ),
                        8.gap,
                        Text(
                          notification.timestamp,
                          style: tt.labelSmall?.copyWith(
                            color: bodyColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElasticSwipeReveal extends StatelessWidget {
  const _ElasticSwipeReveal({
    required this.extent,
    required this.fromLeft,
    required this.height,
    required this.anchorSize,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final double extent;
  final bool fromLeft;
  final double height;
  final double anchorSize;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (extent <= 0) return const SizedBox.shrink();

    final double width = (anchorSize + extent * 0.95).clamp(anchorSize, 280);

    return Align(
      alignment: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(fromLeft ? height / 2 : 12),
                    right: Radius.circular(fromLeft ? 12 : height / 2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: fromLeft ? 0 : null,
              right: fromLeft ? null : 0,
              top: 0,
              bottom: 0,
              width: anchorSize,
              child: Center(
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({
    required this.notification,
    required this.opacity,
  });

  final AppNotification notification;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (notification.thumbnailUrl != null) {
      return Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            notification.thumbnailUrl!,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: opacity,
      child: Icon(
        notification.icon ?? Icons.notifications_outlined,
        size: 24,
        color: notification.iconColor ?? cs.onSurfaceVariant,
      ),
    );
  }
}
