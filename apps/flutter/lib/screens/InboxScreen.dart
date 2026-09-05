import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../components/CustomBackButton.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.timestamp,
    this.isRead = false,
  });
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'New Chapter Update',
      body: 'Solo Leveling: Ragnarok Chapter 45 is now available!',
      icon: PhosphorIcons.bookOpen(),
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationModel(
      id: '2',
      title: 'Achievement Unlocked',
      body: 'You\'ve earned the "Night Owl" badge for reading after midnight!',
      icon: PhosphorIcons.medal(),
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '3',
      title: 'Someone liked your comment',
      body: 'User "MangaLover99" liked your comment on Ordeal Ch. 100.',
      icon: PhosphorIcons.heart(),
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationModel(
      id: '4',
      title: 'System Maintenance',
      body: 'Scheduled maintenance tonight at 2:00 AM UTC.',
      icon: PhosphorIcons.info(),
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteNotification(int index) {
    final removedItem = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _notifications.insert(index, removedItem);
            });
          },
        ),
      ),
    );
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _deleteSelected() {
    setState(() {
      _notifications.removeWhere((n) => _selectedIds.contains(n.id));
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode ? Colors.white10 : Colors.white.withOpacity(0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                }),
              )
            : const CustomBackButton(),
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'Inbox',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(PhosphorIcons.trash(), color: textColor),
              onPressed: _deleteSelected,
            )
          else
            IconButton(
              icon: Icon(PhosphorIcons.checks(), color: textColor),
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n.isRead = true;
                  }
                });
              },
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(textColor)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isSelected = _selectedIds.contains(notification.id);

                return Dismissible(
                  key: Key(notification.id),
                  background: _buildDismissBackground(brandColor, true), // Swipe right: Delete
                  secondaryBackground: _buildDismissBackground(Colors.blue, false), // Swipe left: Mark as Read
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _deleteNotification(index);
                      return true;
                    } else {
                      _markAsRead(index);
                      return false; // Don't actually dismiss the widget
                    }
                  },
                  child: InkWell(
                    onLongPress: () => _toggleSelection(notification.id),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(notification.id);
                      } else {
                        _markAsRead(index);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? brandColor.withOpacity(0.1) : (notification.isRead ? cardColor.withOpacity(0.3) : cardColor),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? brandColor.withOpacity(0.5) : (notification.isRead ? Colors.transparent : brandColor.withOpacity(0.2)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(notification.icon, color: brandColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(notification.timestamp),
                                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.4)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(notification.id),
                              activeColor: brandColor,
                              shape: const CircleBorder(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDismissBackground(Color color, bool isDelete) {
    return Container(
      alignment: isDelete ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: color,
      child: Icon(
        isDelete ? PhosphorIcons.trash() : PhosphorIcons.envelopeOpen(),
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.mailbox(), size: 80, color: textColor.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            'Your inbox is empty',
            style: GoogleFonts.delius(
              textStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
