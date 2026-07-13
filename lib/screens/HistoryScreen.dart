import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../components/OfflineImage.dart';
import '../components/MainNavigationBar.dart';
import '../components/floating_nav_scroll_scope.dart';
import '../theme_provider.dart';
import '../providers/offline_library_provider.dart';
import '../providers/auth_provider.dart';
import '../models/manga.dart';
import '../models/local_models.dart';
import '../services/manga_repository.dart';

import 'MangaDetailsScreen.dart';
import 'MangaReaderScreen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final int _currentIndex = 2; // History is index 2
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<LocalManga> currentList) {
    setState(() {
      if (_selectedIds.length == currentList.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.addAll(currentList.map((e) => e.id));
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _showDeleteConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final ColorScheme cs = Theme.of(context).colorScheme;
        final bool isDarkTheme = themeProvider.isDarkTheme;
        final textColor = cs.onSurface;
        final bgColor = themeProvider.pureBlackDarkMode && isDarkTheme
            ? Colors.black
            : cs.surface;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            content,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<LocalChapter?> _getLastReadChapter(LocalManga manga) async {
    final isar = Provider.of<MangaRepository>(context, listen: false).isar;
    final ownerUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).localScopeUserId;
    return await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(manga.sourceId)
        .mangaIdEqualTo(manga.mangaId)
        .ownerUserIdEqualTo(ownerUserId)
        .sortByLastReadAtDesc()
        .findFirst();
  }

  Future<List<LocalChapter>> _getAllChapters(LocalManga manga) async {
    final repo = Provider.of<MangaRepository>(context, listen: false);
    return await repo.getChapters(manga.sourceId, manga.mangaId);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final brandColor = themeProvider.brandColor;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color backgroundColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surface;
    final Color appBarColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surfaceContainer;
    final Color textColor = cs.onSurface;

    return StreamBuilder<List<LocalManga>>(
      stream: Provider.of<MangaRepository>(context, listen: false).isar
          .collection<LocalManga>()
          .filter()
          .ownerUserIdEqualTo(authProvider.localScopeUserId)
          .lastReadAtIsNotNull()
          .sortByLastReadAtDesc()
          .watch(fireImmediately: true),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final allSelected =
            history.isNotEmpty && _selectedIds.length == history.length;

        return Scaffold(
          extendBody: true,
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: _isSelectionMode
                ? IconButton(
              icon: Icon(Icons.close, color: textColor),
              onPressed: _clearSelection,
            )
                : null,
            title: Text(
              _isSelectionMode ? '${_selectedIds.length} selected' : 'History',
              // style: GoogleFonts.hennyPenny(
              //   textStyle: TextStyle(
              //     fontWeight: FontWeight.bold,
              //     color: textColor,
              //   ),
              // ),
              style: GoogleFonts.unbounded(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: textColor,
                fontSize: 24,
              ),
            ),
            actions: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: allSelected,
                  onChanged: (_) => _selectAll(history),
                  activeColor: brandColor,
                  side: BorderSide(color: cs.onSurfaceVariant, width: 2),
                ),
                IconButton(
                  onPressed: () {
                    _showDeleteConfirmation(
                      context: context,
                      title: "Delete ${_selectedIds.length} items?",
                      content:
                      "Are you sure you want to remove these items from your history?",
                      onConfirm: () async {
                        final isar = Provider.of<MangaRepository>(
                          context,
                          listen: false,
                        ).isar;
                        await isar.writeTxn(() async {
                          final itemsToDelete = await isar
                              .collection<LocalManga>()
                              .filter()
                              .ownerUserIdEqualTo(authProvider.localScopeUserId)
                              .anyOf(_selectedIds, (q, id) => q.idEqualTo(id))
                              .findAll();
                          for (var m in itemsToDelete) {
                            m.lastReadAt = null;
                            await isar.collection<LocalManga>().put(m);
                          }
                        });
                        _clearSelection();
                      },
                    );
                  },
                  icon: Icon(Icons.delete, color: textColor),
                ),
              ] else ...[
                IconButton(
                  onPressed: () {
                    // TODO: Search history
                  },
                  icon: Icon(Icons.search_rounded, color: textColor),
                ),
                IconButton(
                  onPressed: () {
                    if (history.isEmpty) return;
                    _showDeleteConfirmation(
                      context: context,
                      title: "Clear History?",
                      content:
                      "Are you sure you want to clear all reading history?",
                      onConfirm: () async {
                        final isar = Provider.of<MangaRepository>(
                          context,
                          listen: false,
                        ).isar;
                        await isar.writeTxn(() async {
                          for (var m in history) {
                            m.lastReadAt = null;
                            await isar.collection<LocalManga>().put(m);
                          }
                        });
                      },
                    );
                  },
                  icon: Icon(Icons.delete, color: textColor),
                ),
              ],
            ],
          ),

          body: FloatingNavScrollScope(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : history.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  "No reading history",
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final manga = history[index];
              final showDate =
                  index == 0 ||
                      !isSameDay(
                        history[index].lastReadAt!,
                        history[index - 1].lastReadAt!,
                      );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDate)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        formatDate(manga.lastReadAt!),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  HistoryItem(
                    manga: manga,
                    isSelected: _selectedIds.contains(manga.id),
                    isSelectionMode: _isSelectionMode,
                    onTap: () async {
                      if (_isSelectionMode) {
                        _toggleSelection(manga.id);
                      } else {
                        // 1. Get all chapters
                        final chapters = await _getAllChapters(manga);

                        // 2. Find last read chapter
                        final lastReadChapter = await _getLastReadChapter(
                          manga,
                        );

                        if (lastReadChapter != null &&
                            chapters.isNotEmpty) {
                          // 3. Find index of last read chapter in the full list
                          // Note: chapters from repo are usually sorted by number descending
                          final index = chapters.indexWhere(
                                (c) =>
                            c.chapterId == lastReadChapter.chapterId,
                          );

                          if (index != -1) {
                            // 4. Navigate directly to reader
                            // Convert LocalManga to Manga for the reader
                            final mangaObj = Manga(
                              id: manga.mangaId,
                              sourceId: manga.sourceId,
                              title: manga.title,
                              url: "",
                              thumbnailUrl: manga.thumbnailUrl ?? "",
                              description: manga.description ?? "",
                              status: manga.status ?? "Unknown",
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MangaReaderScreen(
                                  manga: mangaObj,
                                  chapters: chapters,
                                  initialChapterIndex: index,
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        // Fallback to details screen if logic fails or no history found
                        final mangaObj = Manga(
                          id: manga.mangaId,
                          sourceId: manga.sourceId,
                          title: manga.title,
                          url: "",
                          thumbnailUrl: manga.thumbnailUrl ?? "",
                          description: manga.description ?? "",
                          status: manga.status ?? "Unknown",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MangaDetailsScreen(manga: mangaObj),
                          ),
                        );
                      }
                    },
                    onLongPress: () => _toggleSelection(manga.id),
                    onDelete: () {
                      _showDeleteConfirmation(
                        context: context,
                        title: "Remove from History?",
                        content:
                        "Are you sure you want to remove '${manga.title}' from your history?",
                        onConfirm: () async {
                          final isar = Provider.of<MangaRepository>(
                            context,
                            listen: false,
                          ).isar;
                          manga.lastReadAt = null;
                          await isar.writeTxn(() async {
                            await isar.collection<LocalManga>().put(
                              manga,
                            );
                          });
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
          ),
          bottomNavigationBar: MainNavigationBar(
            currentIndex: _currentIndex,
            brandColor: brandColor,
          ),
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return "Today";
    if (dateToCheck == yesterday) return "Yesterday";
    final day = date.day;
    final monthAndYear = DateFormat('MMMM yyyy').format(date);
    return '$day${_ordinalSuffix(day)} $monthAndYear';
  }

  String _ordinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }

    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class HistoryItem extends StatefulWidget {
  final LocalManga manga;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const HistoryItem({
    super.key,
    required this.manga,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  State<HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<HistoryItem> {
  LocalChapter? _lastReadChapter;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  @override
  void didUpdateWidget(HistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manga.lastReadAt != widget.manga.lastReadAt) {
      _loadChapter();
    }
  }

  Future<void> _loadChapter() async {
    final isar = Provider.of<MangaRepository>(context, listen: false).isar;
    final ownerUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).localScopeUserId;
    final chapter = await isar
        .collection<LocalChapter>()
        .filter()
        .sourceIdEqualTo(widget.manga.sourceId)
        .mangaIdEqualTo(widget.manga.mangaId)
        .ownerUserIdEqualTo(ownerUserId)
        .sortByLastReadAtDesc()
        .findFirst();
    if (mounted) setState(() => _lastReadChapter = chapter);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final offlineLibrary = Provider.of<OfflineLibraryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final brandColor = themeProvider.brandColor;
    final textColor = cs.onSurface;

    final isInLibrary = offlineLibrary.isInLibrary(
      widget.manga.mangaId,
      widget.manga.sourceId,
    );

    // Convert LocalManga to Manga for toggleLibrary
    final mangaObj = Manga(
      id: widget.manga.mangaId,
      sourceId: widget.manga.sourceId,
      title: widget.manga.title,
      url: "", // Not needed for toggle
      thumbnailUrl: widget.manga.thumbnailUrl ?? "",
      description: widget.manga.description ?? "",
      status: widget.manga.status ?? "Unknown",
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: widget.isSelected
              ? brandColor.withOpacity(0.1)
              : Colors.transparent,
          border: widget.isSelected
              ? Border.all(color: brandColor, width: 1)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: OfflineImage(
                    localFilePath: widget.manga.thumbnailLocalPath,
                    imageUrl: widget.manga.thumbnailUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    fallback: Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.check, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.manga.title,
                    style: GoogleFonts.unbounded(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastReadChapter != null
                        ? "${_lastReadChapter!.name} - ${formatTime(_lastReadChapter!.lastReadAt)}"
                        : "Reading...",
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!widget.isSelectionMode) ...[
              IconButton(
                onPressed: () {
                  if (authProvider.token != null) {
                    offlineLibrary.toggleLibrary(mangaObj);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please login to add to library"),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isInLibrary
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 20,
                  color: isInLibrary ? brandColor : textColor,
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(Icons.delete, size: 20, color: textColor),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onTap(),
                  activeColor: brandColor,
                  side: BorderSide(color: cs.onSurfaceVariant, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String formatTime(DateTime? date) {
    if (date == null) return "";
    return DateFormat('HH:mm').format(date);
  }
}
