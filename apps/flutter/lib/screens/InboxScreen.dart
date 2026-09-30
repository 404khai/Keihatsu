import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notifications_api.dart';
import '../services/sources_api.dart';
import 'MangaDetailsScreen.dart';
import 'MangaReaderScreen.dart';

class InboxScreen extends StatefulWidget {
  final String? initialNotificationId;
  const InboxScreen({super.key, this.initialNotificationId});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final api = NotificationsApi();
  final items = <InboxNotification>[];
  String category = 'ALL';
  String? cursor;
  bool loading = false, loadingMore = false;
  bool consumedInitialTap = false;
  String? error;
  int unreadCount = 0;
  static const categories = ['ALL', 'UPDATES', 'COMMENTS', 'SYSTEM', 'ACCOUNT'];
  String? get token => context.read<AuthProvider>().token;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => refresh()); }

  Future<void> refresh() async {
    final authToken = token;
    if (authToken == null) { setState(() { items.clear(); error = 'Sign in to see your Inbox.'; }); return; }
    setState(() { loading = true; error = null; });
    try {
      final page = await api.list(authToken, category: category);
      final count = await api.unreadCount(authToken);
      if (!mounted) return;
      setState(() { items..clear()..addAll(page.items); cursor = page.nextCursor; unreadCount = count; });
      if (!consumedInitialTap && widget.initialNotificationId != null) {
        final index = items.indexWhere((item) => item.id == widget.initialNotificationId);
        if (index >= 0) {
          consumedInitialTap = true;
          final target = items[index];
          WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) open(target); });
        }
      }
    } catch (_) { if (mounted) setState(() => error = 'Could not load Inbox. Check your connection and retry.'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> loadMore() async {
    final authToken = token, next = cursor;
    if (authToken == null || next == null || loadingMore) return;
    setState(() => loadingMore = true);
    try {
      final page = await api.list(authToken, cursor: next, category: category);
      if (mounted) setState(() { items.addAll(page.items); cursor = page.nextCursor; });
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load more notifications'))); }
    finally { if (mounted) setState(() => loadingMore = false); }
  }

  Future<void> markRead(InboxNotification item) async {
    final authToken = token;
    if (authToken == null || item.isRead) return;
    final index = items.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    setState(() { items[index] = item.withReadAt(DateTime.now()); unreadCount = (unreadCount - 1).clamp(0, 99999); });
    try { await api.markRead(authToken, item.id); }
    catch (_) { if (mounted) setState(() { items[index] = item; unreadCount++; }); }
  }

  Future<void> remove(InboxNotification item) async {
    final authToken = token;
    if (authToken == null) return;
    final index = items.indexOf(item);
    if (index < 0) return;
    setState(() { items.removeAt(index); if (!item.isRead) unreadCount = (unreadCount - 1).clamp(0, 99999); });
    try { await api.delete(authToken, item.id); }
    catch (_) { if (mounted) setState(() { items.insert(index, item); if (!item.isRead) unreadCount++; }); }
  }

  Future<void> readAll() async {
    final authToken = token;
    if (authToken == null) return;
    final before = List<InboxNotification>.of(items), previousCount = unreadCount;
    setState(() { for (var i = 0; i < items.length; i++) { items[i] = items[i].withReadAt(DateTime.now()); } unreadCount = 0; });
    try { await api.readAll(authToken); }
    catch (_) { if (mounted) setState(() { items..clear()..addAll(before); unreadCount = previousCount; }); }
  }

  Future<void> open(InboxNotification item) async {
    await markRead(item);
    if (!mounted) return;
    final uri = Uri.tryParse(item.deepLink);
    if (uri?.scheme != 'keihatsu') return;
    final sourceId = item.sourceId, mangaId = item.mangaId;
    if (sourceId == null || mangaId == null || sourceId.isEmpty || mangaId.isEmpty) return;
    try {
      final source = SourcesApi();
      final manga = await source.getMangaDetails(sourceId, mangaId);
      if (!mounted) return;
      if ((uri!.host == 'chapter' || uri.host == 'comment') && item.chapterId != null) {
        final chapters = await source.getChapters(sourceId, mangaId);
        final index = chapters.indexWhere((chapter) => chapter.id == item.chapterId);
        if (!mounted || index < 0) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => MangaReaderScreen(
          manga: manga, chapters: chapters, initialChapterIndex: index,
          openComments: uri.host == 'comment')));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => MangaDetailsScreen(manga: manga)));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destination is unavailable'))); }
  }

  IconData icon(String type) => type == 'CHAPTER_UPDATE' ? Icons.menu_book_rounded :
    type.startsWith('COMMENT_') ? Icons.forum_rounded :
    type == 'ACCOUNT_SECURITY' ? Icons.shield_rounded : Icons.notifications_rounded;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Inbox${unreadCount > 0 ? ' ($unreadCount)' : ''}'), actions: [
      IconButton(tooltip: 'Notification preferences', onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())), icon: const Icon(Icons.tune)),
      TextButton(onPressed: unreadCount == 0 ? null : readAll, child: const Text('Read all')),
    ]),
    body: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(12),
        child: Row(children: categories.map((value) => Padding(padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(label: Text(value[0] + value.substring(1).toLowerCase()),
            selected: category == value, onSelected: (_) { setState(() => category = value); refresh(); }))).toList())),
      Expanded(child: loading && items.isEmpty ? const Center(child: CircularProgressIndicator()) :
        error != null && items.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!), const SizedBox(height: 12), FilledButton(onPressed: refresh, child: const Text('Retry'))])) :
        RefreshIndicator(onRefresh: refresh, child: items.isEmpty ?
          ListView(children: const [SizedBox(height: 180), Center(child: Text('You are all caught up'))]) :
          ListView.builder(itemCount: items.length + (cursor == null ? 0 : 1), itemBuilder: (context, index) {
            if (index == items.length) { WidgetsBinding.instance.addPostFrameCallback((_) => loadMore()); return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())); }
            final item = items[index];
            return Dismissible(key: ValueKey(item.id), direction: DismissDirection.endToStart,
              background: const ColoredBox(color: Colors.red, child: Align(alignment: Alignment.centerRight, child: Padding(
                padding: EdgeInsets.all(16), child: Icon(Icons.delete, color: Colors.white)))),
              onDismissed: (_) => remove(item), child: ListTile(
                leading: Icon(icon(item.type)),
                title: Row(children: [Expanded(child: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold))),
                  if (!item.isRead) const CircleAvatar(radius: 4)]),
                subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(_relative(item.createdAt)), onTap: () => open(item),
                onLongPress: () => markRead(item),
              ));
          }))),
    ]),
  );

  String _relative(DateTime timestamp) {
    final age = DateTime.now().difference(timestamp.toLocal());
    if (age.inMinutes < 1) return 'Now';
    if (age.inHours < 1) return '${age.inMinutes}m';
    if (age.inDays < 1) return '${age.inHours}h';
    return '${age.inDays}d';
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final api = NotificationsApi();
  Map<String, dynamic>? values;
  String? error;
  static const labels = <String, String>{
    'libraryUpdates': 'New chapters', 'commentReplies': 'Replies',
    'commentMentions': 'Mentions', 'commentLikes': 'Likes',
    'sourceStatus': 'Source status', 'productAnnouncements': 'Product announcements',
  };
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => load()); }
  Future<void> load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try { final result = await api.preferences(token); if (mounted) setState(() { values = result; error = null; }); }
    catch (_) { if (mounted) setState(() => error = 'Could not load preferences'); }
  }
  Future<void> update(String key, bool value) async {
    final token = context.read<AuthProvider>().token, previous = values?[key];
    if (token == null) return;
    setState(() => values?[key] = value);
    try { await api.updatePreferences(token, {key: value}); }
    catch (_) { if (mounted) setState(() { values?[key] = previous; error = 'Could not save preference'; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Notification preferences')),
    body: values == null ? Center(child: error == null ? const CircularProgressIndicator() :
      TextButton(onPressed: load, child: Text('$error — Retry'))) : ListView(children: [
        if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
        ...labels.entries.map((entry) => SwitchListTile(title: Text(entry.value),
          subtitle: const Text('Push alerts. Important events remain in Inbox.'),
          value: values?[entry.key] == true, onChanged: (value) => update(entry.key, value))),
      ]));
}
