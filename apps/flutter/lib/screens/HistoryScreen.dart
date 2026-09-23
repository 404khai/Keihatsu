import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../components/OfflineImage.dart';
import '../components/MainNavigationBar.dart';
import '../components/floating_nav_scroll_scope.dart';
import '../components/gradient_fade_app_bar.dart';
import '../components/menu/bottom_padding.dart';
import '../providers/floating_nav_provider.dart';
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

class _HistoryScreenState extends State<HistoryScreen>
    with GradientFadeAppBarMixin {
  final int _currentIndex = 2; // History is index 2
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  Stream<List<LocalManga>>? _historyStream;
  String? _historyOwnerId;

  static const double _navClearance = 88;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FloatingNavProvider>().expand();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ownerId = context.read<AuthProvider>().localScopeUserId;
    if (_historyStream != null && _historyOwnerId == ownerId) return;

    _historyOwnerId = ownerId;
    _historyStream = context
        .read<MangaRepository>()
        .isar
        .collection<LocalManga>()
        .filter()
        .ownerUserIdEqualTo(ownerId)
        .lastReadAtIsNotNull()
        .sortByLastReadAtDesc()
        .watch(fireImmediately: true);
  }

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
          content: Text(content, style: TextStyle(color: cs.onSurfaceVariant)),
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

  Manga _mangaFromHistory(LocalManga manga) {
    return Manga(
      id: manga.mangaId,
      sourceId: manga.sourceId,
      title: manga.title,
      url: "",
      thumbnailUrl: manga.thumbnailUrl ?? "",
      description: manga.description ?? "",
      status: manga.status ?? "Unknown",
    );
  }

  void _openMangaDetails(LocalManga manga) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MangaDetailsScreen(manga: _mangaFromHistory(manga)),
      ),
    );
  }

  Future<void> _openLastReadChapter(LocalManga manga) async {
    final chapters = await _getAllChapters(manga);
    final lastReadChapter = await _getLastReadChapter(manga);
    if (!mounted) return;

    if (lastReadChapter != null && chapters.isNotEmpty) {
      final index = chapters.indexWhere(
        (chapter) => chapter.chapterId == lastReadChapter.chapterId,
      );
      if (index != -1) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaReaderScreen(
              manga: _mangaFromHistory(manga),
              chapters: chapters,
              initialChapterIndex: index,
            ),
          ),
        );
        return;
      }
    }

    if (mounted) _openMangaDetails(manga);
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
      stream: _historyStream,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final allSelected =
            history.isNotEmpty && _selectedIds.length == history.length;

        return Scaffold(
          extendBody: true,
          backgroundColor: backgroundColor,
          appBar: GradientFadeAppBar(
            baseColor: appBarColor,
            fadeAmount: appBarFade,
            automaticallyImplyLeading: false,
            leading: _isSelectionMode
                ? IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: _clearSelection,
                  )
                : null,
            title: Text(
              _isSelectionMode ? '${_selectedIds.length} selected' : 'History',
              // style: GoogleFonts.unbounded(
              //   textStyle: TextStyle(
              //     fontWeight: FontWeight.bold,
              //     color: textColor,
              //   ),
              // ),
              style: GoogleFonts.unbounded(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: textColor,
                fontSize: 20,
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

          body: GradientFadeScrollListener(
            onFadeChanged: updateAppBarFade,
            child: FloatingNavScrollScope(
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
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        BottomPadding.of(context) + _navClearance,
                      ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  formatDate(manga.lastReadAt!),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            HistoryItem(
                              key: ValueKey(manga.id),
                              manga: manga,
                              isSelected: _selectedIds.contains(manga.id),
                              isSelectionMode: _isSelectionMode,
                              onCoverTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(manga.id);
                                } else {
                                  _openMangaDetails(manga);
                                }
                              },
                              onChapterTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(manga.id);
                                } else {
                                  _openLastReadChapter(manga);
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
  final VoidCallback onCoverTap;
  final VoidCallback onChapterTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const HistoryItem({
    super.key,
    required this.manga,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onCoverTap,
    required this.onChapterTap,
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

  void _showCategoryBottomSheet(
    OfflineLibraryProvider offlineLibrary,
    Manga manga,
  ) {
    final themeProvider = context.read<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final background =
        themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme
        ? Colors.black
        : cs.surface;
    final selectedCategories = <String>{'Default'};

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: background,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final categories = [
            'Default',
            ...offlineLibrary.categories.map((category) => category.name),
          ];
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(category),
                          value: selectedCategories.contains(category),
                          activeColor: themeProvider.brandColor,
                          onChanged: (selected) {
                            setSheetState(() {
                              if (selected == true) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        offlineLibrary.toggleLibrary(
                          manga,
                          categories: selectedCategories.toList(),
                        );
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Add to library'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

    return Container(
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
          InkWell(
            onTap: widget.onCoverTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(4),
            child: Stack(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: widget.onChapterTap,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.manga.title,
                      style: GoogleFonts.unbounded(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
            ),
          ),
          if (!widget.isSelectionMode) ...[
            IconButton(
              onPressed: () {
                if (authProvider.token != null) {
                  if (isInLibrary) {
                    offlineLibrary.toggleLibrary(mangaObj);
                  } else {
                    _showCategoryBottomSheet(offlineLibrary, mangaObj);
                  }
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
                    ? PhosphorIcons.bookBookmark(PhosphorIconsStyle.fill)
                    : PhosphorIcons.bookBookmark(),
                color: isInLibrary ? brandColor : textColor,
                size: 20,
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
                onChanged: (_) => widget.onChapterTap(),
                activeColor: brandColor,
                side: BorderSide(color: cs.onSurfaceVariant, width: 2),
              ),
            ),
        ],
      ),
    );
  }

  String formatTime(DateTime? date) {
    if (date == null) return "";
    return DateFormat('HH:mm').format(date);
  }
}
