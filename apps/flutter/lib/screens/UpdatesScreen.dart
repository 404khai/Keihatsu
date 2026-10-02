import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/CustomBackButton.dart';
import '../components/OfflineImage.dart';
import '../components/keihatsu_refresh_indicator.dart';
import '../models/manga.dart';
import '../providers/download_provider.dart';
import '../providers/library_updates_provider.dart';
import '../providers/offline_library_provider.dart';
import '../theme_provider.dart';
import 'MangaDetailsScreen.dart';
import 'UpcomingCalendarScreen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updates = context.read<LibraryUpdatesProvider>();
      if (updates.items.isEmpty) _refresh();
    });
  }

  Future<void> _refresh() {
    return context.read<LibraryUpdatesProvider>().refresh(
      context.read<OfflineLibraryProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final updates = context.watch<LibraryUpdatesProvider>();
    final ColorScheme cs = Theme.of(context).colorScheme;
    final backgroundColor =
        themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme
        ? Colors.black
        : cs.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: KeihatsuRefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: backgroundColor,
                surfaceTintColor: Colors.transparent,
                leading: const CustomBackButton(),
                leadingWidth: 56,
                title: Text(
                  'Updates',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: cs.onSurface,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  PopupMenuButton<LibraryUpdatesFilter>(
                    initialValue: updates.filter,
                    tooltip: 'Filter updates',
                    onSelected: updates.setFilter,
                    icon: Icon(
                      updates.filter == LibraryUpdatesFilter.all
                          ? Icons.filter_list_rounded
                          : Icons.filter_list_off_rounded,
                      color: cs.onSurface,
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: LibraryUpdatesFilter.all,
                        child: Text('All chapters'),
                      ),
                      PopupMenuItem(
                        value: LibraryUpdatesFilter.unread,
                        child: Text('Unread'),
                      ),
                      PopupMenuItem(
                        value: LibraryUpdatesFilter.downloaded,
                        child: Text('Downloaded'),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Upcoming releases',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const UpcomingCalendarScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      color: cs.onSurface,
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LastUpdatedPill(
                      value: updates.lastUpdatedAt,
                      isRefreshing: updates.isLoading,
                    ),
                  ),
                ),
              ),
              if (updates.error != null && updates.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _UpdatesMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not refresh updates',
                    action: _refresh,
                  ),
                )
              else if (!updates.isLoading && updates.groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _UpdatesMessage(
                    icon: Icons.update_rounded,
                    title: updates.filter == LibraryUpdatesFilter.all
                        ? 'No chapter updates yet'
                        : 'No matching updates',
                    action: _refresh,
                  ),
                )
              else
                for (final group in updates.groups) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(group.date),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: group.items.length,
                    itemBuilder: (_, index) =>
                        _UpdateChapterRow(item: group.items[index]),
                  ),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastUpdatedPill extends StatelessWidget {
  const _LastUpdatedPill({required this.value, required this.isRefreshing});

  final DateTime? value;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isRefreshing
        ? 'Checking for new chapters…'
        : value == null
        ? 'Pull to refresh'
        : 'Updated ${DateFormat.jm().format(value!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _UpdateChapterRow extends StatelessWidget {
  const _UpdateChapterRow({required this.item});

  final LibraryUpdateItem item;

  Manga get manga => Manga(
    id: item.libraryEntry.mangaId,
    url: '',
    title: item.libraryEntry.title,
    thumbnailUrl: item.libraryEntry.thumbnailUrl ?? '',
    author: item.libraryEntry.author,
    sourceId: item.libraryEntry.sourceId,
    lang: item.libraryEntry.language,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brandColor = context.watch<ThemeProvider>().brandColor;
    final downloads = context.watch<DownloadProvider>();
    final queued = downloads.queue.where(
      (entry) => entry.chapterId == item.chapter.chapterId,
    );
    final queueItem = queued.isEmpty ? null : queued.first;
    final downloaded = item.chapter.downloaded || queueItem?.status == 2;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MangaDetailsScreen(manga: manga),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Opacity(
          opacity: item.chapter.isRead ? 0.48 : 1,
          child: Row(
            children: [
              OfflineImage(
                imageUrl: item.libraryEntry.thumbnailUrl,
                width: 54,
                height: 70,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.libraryEntry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.chapter.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: downloaded ? 'Downloaded' : 'Download chapter',
                onPressed: downloaded || queueItem != null
                    ? null
                    : () => downloads.addToQueue(
                        item.chapter.mangaId,
                        item.chapter.sourceId,
                        item.chapter.chapterId,
                        item.libraryEntry.title,
                        item.chapter.name,
                        item.chapter.chapterNumber,
                        item.chapter.sourceId,
                        item.libraryEntry.thumbnailUrl,
                      ),
                icon: queueItem?.status == 1
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: brandColor,
                        ),
                      )
                    : Icon(
                        downloaded
                            ? Icons.download_done_rounded
                            : queueItem == null
                            ? Icons.download_for_offline_outlined
                            : Icons.schedule_rounded,
                        color: downloaded ? brandColor : cs.onSurfaceVariant,
                        size: 28,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdatesMessage extends StatelessWidget {
  const _UpdatesMessage({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 42,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: action, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
