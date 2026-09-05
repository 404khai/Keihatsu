import 'package:flutter/material.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/providers/download_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme_provider.dart';
import '../providers/auth_provider.dart';
import '../models/manga.dart';
import '../models/local_models.dart';
import '../services/manga_repository.dart';
import '../providers/offline_library_provider.dart';
import '../components/OfflineImage.dart';
import '../components/loading_indicator.dart';
import 'MangaReaderScreen.dart';

class MangaDetailsScreen extends StatefulWidget {
  final Manga manga;

  const MangaDetailsScreen({super.key, required this.manga});

  @override
  State<MangaDetailsScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends State<MangaDetailsScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _showTitle = false;
  late Future<LocalManga?> _mangaDetailsFuture;
  late Future<List<LocalChapter>> _chaptersFuture;
  List<LocalChapter>? _cachedChapters;
  late Future<List<Manga>> _recommendedMangaFuture;
  bool _showAllChapters = false;
  bool _showFullDescription = false;
  late AnimationController _arrowController;
  bool _filterDownloaded = false;
  bool _filterUnread = false;
  bool _filterBookmarked = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        if (!_showTitle) setState(() => _showTitle = true);
      } else {
        if (_showTitle) setState(() => _showTitle = false);
      }
    });

    final repo = Provider.of<MangaRepository>(context, listen: false);
    _mangaDetailsFuture = repo.getMangaDetails(
      widget.manga.sourceId,
      widget.manga.id,
    );
    _chaptersFuture = repo
        .getChapters(widget.manga.sourceId, widget.manga.id)
        .then((chapters) {
          _cachedChapters = chapters;
          return chapters;
        });
    _recommendedMangaFuture = repo.api
        .getMangaList(widget.manga.sourceId, 'popular')
        .then((p) => p.mangas);

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  Widget _buildDragHandle(Color textColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Color _screenBackground(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme
        ? Colors.black
        : colorScheme.surface;
  }

  Color _loaderColor(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    return themeProvider.brandColor.computeLuminance() > 0.65
        ? colorScheme.onSurface
        : themeProvider.brandColor;
  }

  Widget _buildDetailLoader(BuildContext context) {
    return Center(
      child: KeihatsuLoadingIndicator(
        contained: true,
        color: _loaderColor(context),
      ),
    );
  }

  void _showCategoryBottomSheet(
    BuildContext context,
    OfflineLibraryProvider offlineLibrary,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brandColor = themeProvider.brandColor;
    final bgColor = _screenBackground(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    List<String> selectedCategories = ["Default"];

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allCategories = [
              "Default",
              ...offlineLibrary.categories.map((c) => c.name),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(textColor),
                  Text(
                    "Select Categories",
                    style: GoogleFonts.denkOne(fontSize: 20, color: textColor),
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final catName = allCategories[index];
                        return CheckboxListTile(
                          title: Text(
                            catName,
                            style: TextStyle(color: textColor),
                          ),
                          value: selectedCategories.contains(catName),
                          activeColor: brandColor,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                if (!selectedCategories.contains(catName)) {
                                  selectedCategories.add(catName);
                                }
                              } else {
                                selectedCategories.remove(catName);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        offlineLibrary.toggleLibrary(
                          widget.manga,
                          categories: selectedCategories,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Add to Library",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brandColor = themeProvider.brandColor;
    final bgColor = _screenBackground(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(textColor),
                  Text(
                    "Filter Chapters",
                    style: GoogleFonts.denkOne(fontSize: 20, color: textColor),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: Text(
                      "Downloaded",
                      style: TextStyle(color: textColor),
                    ),
                    value: _filterDownloaded,
                    activeColor: brandColor,
                    onChanged: (val) {
                      setModalState(() => _filterDownloaded = val);
                      this.setState(() {});
                    },
                    secondary: Icon(Icons.download_done, color: textColor),
                  ),
                  SwitchListTile(
                    title: Text("Unread", style: TextStyle(color: textColor)),
                    value: _filterUnread,
                    activeColor: brandColor,
                    onChanged: (val) {
                      setModalState(() => _filterUnread = val);
                      this.setState(() {});
                    },
                    secondary: Icon(PhosphorIcons.eyeSlash(), color: textColor),
                  ),
                  SwitchListTile(
                    title: Text(
                      "Bookmarked",
                      style: TextStyle(color: textColor),
                    ),
                    value: _filterBookmarked,
                    activeColor: brandColor,
                    onChanged: (val) {
                      setModalState(() => _filterBookmarked = val);
                      this.setState(() {});
                    },
                    secondary: Icon(
                      PhosphorIcons.bookmarkSimple(),
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    final bgColor = _screenBackground(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(textColor),
              ListTile(
                leading: Icon(Icons.refresh, color: textColor),
                title: Text("Refresh", style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final repo = Provider.of<MangaRepository>(
                      context,
                      listen: false,
                    );
                    _chaptersFuture = repo
                        .getChapters(widget.manga.sourceId, widget.manga.id)
                        .then((chapters) {
                          _cachedChapters = chapters;
                          return chapters;
                        });
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.move_up, color: textColor),
                title: Text("Migrate", style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Migrate not implemented yet"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: textColor),
                title: Text("Share", style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Share not implemented yet")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadBottomSheet(BuildContext context) {
    if (_cachedChapters == null) return;

    final bgColor = _screenBackground(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final downloadProvider = Provider.of<DownloadProvider>(
      context,
      listen: false,
    );

    // Helper to queue downloads
    void queueDownloads(List<LocalChapter> chapters) {
      for (var chapter in chapters) {
        if (!chapter.downloaded &&
            !downloadProvider.queue.any(
              (i) => i.chapterId == chapter.chapterId,
            )) {
          downloadProvider.addToQueue(
            chapter.mangaId,
            chapter.sourceId,
            chapter.chapterId,
            widget.manga.title,
            chapter.name,
            chapter.chapterNumber,
            widget.manga.sourceId,
            widget.manga.thumbnailUrl,
          );
        }
      }
    }

    // Determine 'next' chapters based on reading progress (or just index 0 if none read)
    // Actually usually "next" means older chapters if reading top-down or newer if bottom-up?
    // Let's assume list is sorted by chapter number descending (newest first).
    // So "next" usually means the next unread chapter in reading order (usually ascending number).
    // But implementation details vary. Let's just take the first N unread/undownloaded from the bottom up?
    // Or just from the current position.
    // Let's implement simple logic: find first unread chapter, then take N chapters after it (chronologically next).

    final sortedChapters = List<LocalChapter>.from(_cachedChapters!);
    // Sort by chapter number ascending for logic
    sortedChapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

    // Find first unread index
    int firstUnreadIndex = sortedChapters.indexWhere((c) => !c.isRead);
    if (firstUnreadIndex == -1)
      firstUnreadIndex = 0; // All read, start from beginning? Or end?

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(textColor),
              ListTile(
                leading: Icon(Icons.download, color: textColor),
                title: Text("Next Chapter", style: TextStyle(color: textColor)),
                onTap: () {
                  if (firstUnreadIndex < sortedChapters.length) {
                    queueDownloads([sortedChapters[firstUnreadIndex]]);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.download, color: textColor),
                title: Text(
                  "Next 5 Chapters",
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  final count = sortedChapters.length;
                  final end = (firstUnreadIndex + 5).clamp(0, count);
                  queueDownloads(sortedChapters.sublist(firstUnreadIndex, end));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.download, color: textColor),
                title: Text(
                  "Next 10 Chapters",
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  final count = sortedChapters.length;
                  final end = (firstUnreadIndex + 10).clamp(0, count);
                  queueDownloads(sortedChapters.sublist(firstUnreadIndex, end));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.eyeSlash(), color: textColor),
                title: Text("Unread", style: TextStyle(color: textColor)),
                onTap: () {
                  queueDownloads(
                    sortedChapters.where((c) => !c.isRead).toList(),
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(PhosphorIcons.bookmarkSimple(), color: textColor),
                title: Text("Bookmarked", style: TextStyle(color: textColor)),
                onTap: () {
                  queueDownloads(
                    sortedChapters.where((c) => c.isBookmarked).toList(),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDownloadsSheet(
    BuildContext context,
    String initialChapterId,
  ) {
    if (_cachedChapters == null) return;

    final downloaded = _cachedChapters!.where((c) => c.downloaded).toList();
    if (downloaded.isEmpty) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brandColor = themeProvider.brandColor;
    final bgColor = _screenBackground(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    Set<String> selectedIds = {initialChapterId};

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Delete Downloads",
                        style: GoogleFonts.denkOne(
                          fontSize: 20,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () async {
                                final toDelete = downloaded
                                    .where(
                                      (c) => selectedIds.contains(c.chapterId),
                                    )
                                    .toList();
                                final downloadProvider =
                                    Provider.of<DownloadProvider>(
                                      context,
                                      listen: false,
                                    );
                                await downloadProvider.deleteChapters(toDelete);

                                // Update local cache
                                for (var c in toDelete) {
                                  c.downloaded = false;
                                }

                                Navigator.pop(context);
                                setState(() {}); // Refresh UI
                              },
                        child: Text(
                          "Delete (${selectedIds.length})",
                          style: TextStyle(
                            color: selectedIds.isEmpty
                                ? Colors.grey
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: downloaded.length,
                      itemBuilder: (context, index) {
                        final chapter = downloaded[index];
                        final isSelected = selectedIds.contains(
                          chapter.chapterId,
                        );
                        return CheckboxListTile(
                          title: Text(
                            chapter.name,
                            style: TextStyle(color: textColor),
                          ),
                          value: isSelected,
                          activeColor: brandColor,
                          checkColor: Colors.white,
                          side: BorderSide(color: textColor.withOpacity(0.5)),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true)
                                selectedIds.add(chapter.chapterId);
                              else
                                selectedIds.remove(chapter.chapterId);
                            });
                          },
                          secondary: Icon(
                            Icons.delete_outline,
                            color: textColor.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Determine which chapter to continue reading from
  LocalChapter? _getContinueChapter(List<LocalChapter> chapters) {
    if (chapters.isEmpty) return null;

    // 1. Find the most recently read chapter
    final readChapters = chapters.where((c) => c.lastReadAt != null).toList()
      ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));

    if (readChapters.isEmpty) {
      // No history: Start from the first chapter (oldest)
      // Assuming 'chapters' list is typically sorted by number descending (newest first).
      // If we want to start at Ch 1, we take the last element.
      // But let's verify sort. Usually repo returns sorted by number desc.
      return chapters.last;
    }

    final lastRead = readChapters.first;

    // 2. If unfinished, continue it
    if (!lastRead.isRead) {
      return lastRead;
    }

    // 3. If finished, find the next chapter (number > lastRead.number)
    // We assume 'chapters' is sorted by number descending.
    // So the "next" chapter (higher number) is at index - 1.
    final index = chapters.indexOf(lastRead);
    if (index > 0) {
      return chapters[index - 1];
    }

    // If it was the latest chapter, just stay on it
    return lastRead;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final offlineLibrary = Provider.of<OfflineLibraryProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = _screenBackground(context);
    final colorScheme = Theme.of(context).colorScheme;
    final Color cardColor = colorScheme.surfaceContainer;
    final Color textColor = colorScheme.onSurface;
    final bool isInLibrary = offlineLibrary.isInLibrary(
      widget.manga.id,
      widget.manga.sourceId,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<LocalManga?>(
        future: _mangaDetailsFuture,
        builder: (context, mangaSnapshot) {
          if (mangaSnapshot.connectionState == ConnectionState.waiting &&
              !mangaSnapshot.hasData) {
            return _buildDetailLoader(context);
          }

          final manga = mangaSnapshot.data;
          final displayTitle = manga?.title ?? widget.manga.title;
          final displayThumbUrl = manga?.thumbnailUrl?.trim().isNotEmpty == true
              ? manga!.thumbnailUrl
              : widget.manga.thumbnailUrl;
          final displayDescription =
              manga?.description ?? widget.manga.description;
          final displayAuthor = manga?.author ?? widget.manga.author;
          final displayStatus = manga?.status ?? widget.manga.status;
          final displayGenres = manga?.genres ?? widget.manga.genres;
          final appBarForeground = _showTitle ? textColor : Colors.white;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OfflineImage(
                        imageUrl: displayThumbUrl,
                        localFilePath: manga?.thumbnailLocalPath,
                        fit: BoxFit.cover,
                        fallback: Container(color: bgColor),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.3), bgColor],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    backgroundColor: _showTitle ? bgColor : Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    leading: const CustomBackButton(),
                    title: _showTitle
                        ? Text(
                            displayTitle,
                            style: GoogleFonts.hennyPenny(
                              textStyle: TextStyle(
                                color: appBarForeground,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    actions: [
                      IconButton(
                        onPressed: () => _showDownloadBottomSheet(context),
                        icon: Icon(Icons.download, color: appBarForeground),
                      ),
                      IconButton(
                        onPressed: () => _showFilterBottomSheet(context),
                        icon: Icon(Icons.filter_list, color: appBarForeground),
                      ),
                      IconButton(
                        onPressed: () => _showMoreBottomSheet(context),
                        icon: Icon(Icons.more_vert, color: appBarForeground),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: OfflineImage(
                                    imageUrl: displayThumbUrl,
                                    localFilePath: manga?.thumbnailLocalPath,
                                    height: 180,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    fallback: Container(
                                      height: 180,
                                      width: 120,
                                      color: cardColor,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: textColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayTitle,
                                      style: GoogleFonts.hennyPenny(
                                        textStyle: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 10.0,
                                              color: Colors.black,
                                              offset: Offset(2.0, 2.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      PhosphorIcons.user(),
                                      displayAuthor ?? "Unknown",
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      PhosphorIcons.clock(),
                                      "${displayStatus ?? "Ongoing"} • ${widget.manga.sourceId.toUpperCase()}",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(
                                isInLibrary
                                    ? PhosphorIcons.bookBookmark(
                                        PhosphorIconsStyle.fill,
                                      )
                                    : PhosphorIcons.bookBookmark(),
                                isInLibrary ? "In library" : "Add to library",
                                brandColor,
                                onTap: () {
                                  if (isInLibrary) {
                                    offlineLibrary.toggleLibrary(widget.manga);
                                  } else {
                                    _showCategoryBottomSheet(
                                      context,
                                      offlineLibrary,
                                    );
                                  }
                                },
                              ),
                              _buildActionButton(
                                PhosphorIcons.hourglassHigh(),
                                "Syncing",
                                colorScheme.onSurfaceVariant,
                              ),
                              _buildActionButton(
                                PhosphorIcons.arrowsClockwise(),
                                "Tracking",
                                colorScheme.onSurfaceVariant,
                              ),
                              _buildActionButton(
                                PhosphorIcons.globe(),
                                "WebView",
                                colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (displayGenres != null)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: displayGenres
                                          .map(
                                            (genre) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 10,
                                              ),
                                              child: _buildTag(
                                                "# ${genre.toUpperCase()}",
                                                brandColor,
                                                textColor,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                const SizedBox(height: 15),
                                Text(
                                  displayDescription ??
                                      "No description available.",
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                                  maxLines: _showFullDescription ? null : 5,
                                  overflow: _showFullDescription
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                if ((displayDescription?.length ?? 0) >
                                    100) // Simple heuristic
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _showFullDescription =
                                          !_showFullDescription,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Icon(
                                        _showFullDescription
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        color: brandColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          FutureBuilder<List<LocalChapter>>(
                            future: _chaptersFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return _buildDetailLoader(context);
                              }
                              if (snapshot.hasError) {
                                return Text(
                                  'Unable to load chapters',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              final chapters = snapshot.data!;
                              var filteredChapters = chapters.where((c) {
                                if (_filterDownloaded && !c.downloaded)
                                  return false;
                                if (_filterUnread && c.isRead) return false;
                                if (_filterBookmarked && !c.isBookmarked)
                                  return false;
                                return true;
                              }).toList();

                              final displayedChapters = _showAllChapters
                                  ? filteredChapters
                                  : filteredChapters.take(3).toList();

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${filteredChapters.length} Chapters",
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...displayedChapters.map(
                                      (ch) => _buildChapterTile(
                                        context,
                                        chapters,
                                        chapters.indexOf(ch),
                                        brandColor,
                                        textColor,
                                      ),
                                    ),
                                    if (!_showAllChapters &&
                                        chapters.length > 3)
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _showAllChapters = true,
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _arrowController,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                0,
                                                10 * _arrowController.value,
                                              ),
                                              child: child,
                                            );
                                          },
                                          child: Icon(
                                            Icons
                                                .keyboard_double_arrow_down_rounded,
                                            color: brandColor,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // "You may also like" Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "You may also like",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: textColor,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "More",
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          PhosphorIcons.caretRight(),
                                          color: colorScheme.onSurfaceVariant,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 200,
                                  child: FutureBuilder<List<Manga>>(
                                    future: _recommendedMangaFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          !snapshot.hasData) {
                                        return _buildDetailLoader(context);
                                      }
                                      if (snapshot.hasError) {
                                        return Text(
                                          'Unable to load recommendations',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      }
                                      final recommendations = snapshot.data!
                                          .where((m) => m.id != widget.manga.id)
                                          .take(6)
                                          .toList();
                                      return ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: recommendations.length,
                                        itemBuilder: (context, index) {
                                          final recommendation =
                                              recommendations[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 15,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MangaDetailsScreen(
                                                          manga: recommendation,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: SizedBox(
                                                width: 100,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: OfflineImage(
                                                        imageUrl: recommendation
                                                            .thumbnailUrl,
                                                        width: 100,
                                                        height: 140,
                                                        fit: BoxFit.cover,
                                                        fallback: Container(
                                                          width: 100,
                                                          height: 140,
                                                          color: cardColor,
                                                          child: Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            color: textColor
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      recommendation.title,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color: textColor,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Bar
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.inverseSurface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showDownloadBottomSheet(context),
                        child: _buildBottomIconButton(
                          Icons.download,
                          colorScheme.onInverseSurface,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FutureBuilder<List<LocalChapter>>(
                          future: _chaptersFuture,
                          builder: (context, snapshot) {
                            final chapters = snapshot.data;
                            final hasChapters =
                                chapters != null && chapters.isNotEmpty;

                            LocalChapter? targetChapter;
                            bool hasHistory = false;

                            if (hasChapters) {
                              targetChapter = _getContinueChapter(chapters);
                              hasHistory = chapters.any(
                                (c) => c.lastReadAt != null,
                              );
                            }

                            return GestureDetector(
                              onTap: (hasChapters && targetChapter != null)
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MangaReaderScreen(
                                                manga: widget.manga,
                                                chapters: chapters,
                                                initialChapterIndex: chapters
                                                    .indexOf(targetChapter!),
                                              ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    }
                                  : null,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: hasChapters
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.surfaceContainerHighest
                                            .withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    hasHistory ? "Continue" : "Read now",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          if (isInLibrary) {
                            offlineLibrary.toggleLibrary(widget.manga);
                          } else {
                            _showCategoryBottomSheet(context, offlineLibrary);
                          }
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorScheme.onInverseSurface.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            isInLibrary
                                ? PhosphorIcons.bookBookmark(
                                    PhosphorIconsStyle.fill,
                                  )
                                : PhosphorIcons.bookBookmark(),
                            color: isInLibrary
                                ? brandColor
                                : colorScheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomIconButton(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onInverseSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildInfoRow(PhosphorIconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    PhosphorIconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color brandColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildChapterTile(
    BuildContext context,
    List<LocalChapter> chapters,
    int index,
    Color brandColor,
    Color textColor,
  ) {
    final chapter = chapters[index];
    final repo = Provider.of<MangaRepository>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final dateStr = DateFormat(
      'MM/dd/yy',
    ).format(DateTime.fromMillisecondsSinceEpoch(chapter.dateUpload));
    final isDownloading = downloadProvider.queue.any(
      (i) => i.chapterId == chapter.chapterId && i.status == 1,
    );

    // Check if in queue (status 0: Queued, 4: Paused)
    final isQueued = downloadProvider.queue.any(
      (i) =>
          i.chapterId == chapter.chapterId && (i.status == 0 || i.status == 4),
    );

    final isRead = chapter.isRead;
    final isBookmarked = chapter.isBookmarked;
    final tileTextColor = isRead ? textColor.withOpacity(0.5) : textColor;

    return Dismissible(
      key: Key(chapter.chapterId),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.blueGrey,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          isRead ? PhosphorIcons.eyeSlash() : PhosphorIcons.eye(),
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Bookmark
          await repo.toggleChapterBookmark(
            chapter,
            !isBookmarked,
            token: auth.token,
          );
          setState(() {}); // Refresh UI
          return false;
        } else {
          // Swipe Left -> Read
          await repo.toggleChapterRead(chapter, !isRead, token: auth.token);
          setState(() {}); // Refresh UI
          return false;
        }
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MangaReaderScreen(
                manga: widget.manga,
                chapters: chapters,
                initialChapterIndex: index,
              ),
            ),
          ).then((_) => setState(() {})); // Refresh on return
        },
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.circle(PhosphorIconsStyle.fill),
              size: 10,
              color: isRead ? textColor.withOpacity(0.5) : brandColor,
            ),
            if (isBookmarked) ...[
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
                size: 16,
                color: Colors.green,
              ),
            ],
          ],
        ),
        title: Text(chapter.name, style: TextStyle(color: tileTextColor)),
        subtitle: Text(
          dateStr,
          style: TextStyle(fontSize: 12, color: tileTextColor.withOpacity(0.6)),
        ),
        trailing: IconButton(
          icon: isDownloading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: brandColor,
                  ),
                )
              : Icon(
                  chapter.downloaded
                      ? Icons.check_circle
                      : isQueued
                      ? PhosphorIcons.clock()
                      : Icons.download,
                  color: chapter.downloaded
                      ? Colors.green
                      : isQueued
                      ? Colors.orange
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          onPressed: (isDownloading || isQueued)
              ? null
              : chapter.downloaded
              ? () => _showDeleteDownloadsSheet(context, chapter.chapterId)
              : () => downloadProvider.addToQueue(
                  chapter.mangaId,
                  chapter.sourceId,
                  chapter.chapterId,
                  widget.manga.title,
                  chapter.name,
                  chapter.chapterNumber,
                  widget.manga.sourceId,
                  widget.manga.thumbnailUrl,
                ),
        ),
      ),
    );
  }
}
