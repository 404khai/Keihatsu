import 'dart:io';
import 'dart:async'; // Added
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../models/local_models.dart';
import '../services/manga_repository.dart';
import '../providers/auth_provider.dart'; // Added
import '../providers/comments_provider.dart'; // Added
import '../components/Comments.dart';
import '../components/CustomBackButton.dart';

class MangaReaderScreen extends StatefulWidget {
  final Manga manga;
  final List<dynamic> chapters; // Can be List<Chapter> or List<LocalChapter>
  final int initialChapterIndex;

  const MangaReaderScreen({
    super.key,
    required this.manga,
    required this.chapters,
    required this.initialChapterIndex,
  });

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  static const String _browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36';
  late int _currentChapterIndex;
  double _sliderValue = 1;
  bool _showControls = true;
  bool _isLoading = true;
  bool _isAppendingNextChapter = false;
  final Map<int, List<dynamic>> _chapterPages = {};
  final List<_ReaderItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPageIndex = 0;
  int _bottomChapterIndex = 0;

  // History tracking
  Timer? _debounceTimer;
  final Stopwatch _readingTimer = Stopwatch();
  LocalManga? _localManga;

  @override
  void initState() {
    super.initState();
    _readingTimer.start();
    _currentChapterIndex = widget.initialChapterIndex;
    _bottomChapterIndex = _currentChapterIndex;
    _loadLocalManga();
    _loadInitialChapter();

    _scrollController.addListener(() {
      if (_items.isNotEmpty) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        if (maxScroll > 0) {
          final estimatedIndex = ((currentScroll / maxScroll) * (_items.length - 1))
              .clamp(0, _items.length - 1)
              .round();

          final nearestImageItem = _nearestImageItem(estimatedIndex);
          if (nearestImageItem != null) {
            final chapterPages = _chapterPages[nearestImageItem.chapterIndex] ?? [];
            final sliderValue = (nearestImageItem.pageIndex + 1)
                .toDouble()
                .clamp(
              1.0,
              chapterPages.isEmpty ? 1.0 : chapterPages.length.toDouble(),
            )
                .toDouble();

            if (mounted) {
              setState(() {
                _currentChapterIndex = nearestImageItem.chapterIndex;
                _currentPageIndex = nearestImageItem.pageIndex;
                _sliderValue = sliderValue;
              });
            }

            if (chapterPages.isNotEmpty) {
              _debounceSaveProgress(
                nearestImageItem.chapterIndex,
                nearestImageItem.pageIndex,
                chapterPages.length,
              );
            }
          }

          if (currentScroll >= maxScroll - 800) {
            _maybeAppendNextChapter();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    final chapterPages = _chapterPages[_currentChapterIndex];
    if (chapterPages != null && chapterPages.isNotEmpty) {
      _saveProgress(_currentChapterIndex, _currentPageIndex, chapterPages.length);
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalManga() async {
    final repo = Provider.of<MangaRepository>(context, listen: false);
    // Ensure we have a local manga record to attach history to
    _localManga = await repo.getMangaDetails(
      widget.manga.sourceId,
      widget.manga.id,
    );
  }

  void _debounceSaveProgress(
      int chapterIndex,
      int pageIndex,
      int totalPages,
      ) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _saveProgress(chapterIndex, pageIndex, totalPages);
    });
  }

  Future<void> _saveProgress(
      int chapterIndex,
      int pageIndex,
      int totalPages,
      ) async {
    if (!mounted || _localManga == null) return;
    try {
      final repo = Provider.of<MangaRepository>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final chapter = widget.chapters[chapterIndex];
      final chapterId = _getChapterId(chapter);

      final isRead = totalPages > 0 && pageIndex >= totalPages - 1;

      final readingTimeMs = _readingTimer.elapsedMilliseconds;
      _readingTimer.reset();

      await repo.updateReadingProgress(
        manga: _localManga!,
        chapterId: chapterId,
        pageIndex: pageIndex,
        token: auth.token,
        isRead: isRead,
        readingTimeMs: readingTimeMs,
      );

      // Update local object state to reflect change immediately in UI if needed
      if (chapter is LocalChapter && isRead) {
        chapter.isRead = true;
      }
    } catch (e) {
      print("Error saving progress: $e");
    }
  }

  String _getChapterId(dynamic chapter) {
    return chapter is Chapter ? chapter.id : (chapter as LocalChapter).chapterId;
  }

  String _getChapterName(dynamic chapter) {
    return chapter is Chapter ? chapter.name : (chapter as LocalChapter).name;
  }

  Map<String, String>? _buildImageHeaders(String? referer) {
    if (widget.manga.sourceId.toLowerCase() != 'batcave') {
      return null;
    }

    return {
      'User-Agent': _browserUserAgent,
      'Referer': referer?.isNotEmpty == true ? referer! : widget.manga.url,
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };
  }

  Future<List<dynamic>> _fetchPagesForChapter(int chapterIndex) async {
    final repo = Provider.of<MangaRepository>(context, listen: false);
    final chapter = widget.chapters[chapterIndex];
    final chapterId = _getChapterId(chapter);

    final localPages = await repo.getChapterPages(chapterId);
    bool useLocal = false;

    if (localPages.isNotEmpty) {
      if (localPages.first.imageLocalPath != null) {
        final file = File(localPages.first.imageLocalPath!);
        if (await file.exists()) {
          useLocal = true;
        }
      }
    }

    if (useLocal) {
      return localPages;
    }

    try {
      final archivePages = await repo.getChapterArchivePages(
        widget.manga.sourceId,
        widget.manga.id,
        chapterId,
      );
      if (archivePages.isNotEmpty) return archivePages;
    } catch (e) {
      print('Error reading downloaded CBZ: $e');
    }

    final remotePages = await repo.api.getPages(widget.manga.sourceId, chapterId);
    return remotePages;
  }

  void _addChapterItems(int chapterIndex, List<dynamic> pages) {
    for (int i = 0; i < pages.length; i++) {
      _items.add(
        _ReaderImageItem(
          chapterIndex: chapterIndex,
          pageIndex: i,
          page: pages[i],
        ),
      );
    }
  }

  Future<void> _loadInitialChapter() async {
    setState(() {
      _isLoading = true;
      _items.clear();
      _chapterPages.clear();
      _sliderValue = 1;
    });

    try {
      final pages = await _fetchPagesForChapter(_currentChapterIndex);
      _chapterPages[_currentChapterIndex] = pages;
      _addChapterItems(_currentChapterIndex, pages);

      setState(() {
        _isLoading = false;
      });

      if (_localManga != null) {
        _saveProgress(_currentChapterIndex, 0, pages.length);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          final chapterPages = _chapterPages[_currentChapterIndex];
          if (mounted && _localManga != null && chapterPages != null) {
            _saveProgress(_currentChapterIndex, 0, chapterPages.length);
          }
        });
      }

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading pages: $e')));
      }
    }
  }

  _ReaderImageItem? _nearestImageItem(int startIndex) {
    if (_items.isEmpty) return null;

    if (_items[startIndex] is _ReaderImageItem) {
      return _items[startIndex] as _ReaderImageItem;
    }

    for (int delta = 1; delta < _items.length; delta++) {
      final left = startIndex - delta;
      if (left >= 0 && _items[left] is _ReaderImageItem) {
        return _items[left] as _ReaderImageItem;
      }
      final right = startIndex + delta;
      if (right < _items.length && _items[right] is _ReaderImageItem) {
        return _items[right] as _ReaderImageItem;
      }
    }

    return null;
  }

  bool _hasPreviousChapter() {
    return _currentChapterIndex < widget.chapters.length - 1;
  }

  bool _hasNextChapter() {
    return _currentChapterIndex > 0;
  }

  void _goToPreviousChapter() {
    setState(() => _currentChapterIndex++);
    _bottomChapterIndex = _currentChapterIndex;
    _loadInitialChapter();
  }

  void _goToNextChapter() {
    setState(() => _currentChapterIndex--);
    _bottomChapterIndex = _currentChapterIndex;
    _loadInitialChapter();
  }

  void _scrollToPage(int pageIndex) {
    final chapterPages = _chapterPages[_currentChapterIndex];
    if (chapterPages == null || chapterPages.isEmpty || !_scrollController.hasClients) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final itemIndex = _items.indexWhere(
          (item) =>
      item is _ReaderImageItem &&
          item.chapterIndex == _currentChapterIndex &&
          item.pageIndex == pageIndex,
    );
    if (itemIndex == -1) return;

    final targetOffset = (_items.length <= 1)
        ? 0.0
        : (itemIndex / (_items.length - 1)) * maxScroll;
    _scrollController.jumpTo(targetOffset);
  }

  Future<void> _maybeAppendNextChapter() async {
    if (_isLoading || _isAppendingNextChapter) return;
    if (_bottomChapterIndex <= 0) return;

    final nextChapterIndex = _bottomChapterIndex - 1;
    if (_chapterPages.containsKey(nextChapterIndex)) return;

    setState(() => _isAppendingNextChapter = true);

    try {
      final previousChapter = widget.chapters[_bottomChapterIndex];
      final currentChapter = widget.chapters[nextChapterIndex];

      final nextPages = await _fetchPagesForChapter(nextChapterIndex);
      _chapterPages[nextChapterIndex] = nextPages;

      _items.add(
        _ReaderChapterSeparatorItem(
          previousChapterName: _getChapterName(previousChapter),
          currentChapterName: _getChapterName(currentChapter),
        ),
      );
      _addChapterItems(nextChapterIndex, nextPages);

      _bottomChapterIndex = nextChapterIndex;

      if (_localManga != null) {
        _saveProgress(nextChapterIndex, 0, nextPages.length);
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          final chapterPages = _chapterPages[nextChapterIndex];
          if (mounted && _localManga != null && chapterPages != null) {
            _saveProgress(nextChapterIndex, 0, chapterPages.length);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading next chapter: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAppendingNextChapter = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final currentChapter = widget.chapters[_currentChapterIndex];
    final chapterName = _getChapterName(currentChapter);
    final currentChapterPages = _chapterPages[_currentChapterIndex] ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
                : _items.isEmpty
                ? const Center(
              child: Text(
                "No pages found",
                style: TextStyle(color: Colors.white),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _items.length + (_isAppendingNextChapter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  );
                }

                final item = _items[index];

                if (item is _ReaderChapterSeparatorItem) {
                  return _ChapterSeparator(
                    previousChapterName: item.previousChapterName,
                    currentChapterName: item.currentChapterName,
                  );
                }

                final imageItem = item as _ReaderImageItem;
                final page = imageItem.page;
                ImageProvider imageProvider;

                if (page is Uint8List) {
                  imageProvider = MemoryImage(page);
                } else if (page is LocalPage && page.imageLocalPath != null) {
                  imageProvider = FileImage(File(page.imageLocalPath!));
                } else {
                  final url = page is LocalPage
                      ? page.imageRemoteUrl
                      : page.imageUrl;
                  final referer = page is ReaderPage ? page.url : null;
                  imageProvider = NetworkImage(
                    url,
                    headers: _buildImageHeaders(referer),
                  );
                }

                return Image(
                  image: imageProvider,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 400,
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white24,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 400,
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const CustomBackButton(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.manga.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                chapterName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_showControls)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildChapterButton(
                      icon: PhosphorIcons.skipBack(PhosphorIconsStyle.fill),
                      onPressed: _hasPreviousChapter()
                          ? _goToPreviousChapter
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${_sliderValue.toInt()}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  activeTrackColor: brandColor,
                                  inactiveTrackColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  thumbColor: brandColor,
                                  thumbShape: VerticalBarThumbShape(
                                    color: brandColor,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  trackShape:
                                  const RoundedRectSliderTrackShape(),
                                ),
                                child: Slider(
                                  value: _sliderValue,
                                  min: 1,
                                  max: currentChapterPages.isEmpty
                                      ? 1
                                      : currentChapterPages.length.toDouble(),
                                  divisions: currentChapterPages.isEmpty
                                      ? 1
                                      : currentChapterPages.length - 1,
                                  onChanged: (val) {
                                    setState(() => _sliderValue = val);
                                    _scrollToPage(val.toInt() - 1);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              "${currentChapterPages.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildChapterButton(
                      icon: PhosphorIcons.skipForward(PhosphorIconsStyle.fill),
                      onPressed: _hasNextChapter() ? _goToNextChapter : null,
                    ),
                  ],
                ),
              ),
            ),

          if (_showControls)
            Positioned(
              right: 16,
              bottom: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        (currentChapter is LocalChapter &&
                            currentChapter.isBookmarked)
                            ? PhosphorIcons.bookmarkSimple(
                          PhosphorIconsStyle.fill,
                        )
                            : PhosphorIcons.bookmarkSimple(),
                        color:
                        (currentChapter is LocalChapter &&
                            currentChapter.isBookmarked)
                            ? Colors.green
                            : Colors.white,
                      ),
                      onPressed: () async {
                        if (currentChapter is LocalChapter) {
                          final repo = Provider.of<MangaRepository>(
                            context,
                            listen: false,
                          );
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          await repo.toggleChapterBookmark(
                            currentChapter,
                            !currentChapter.isBookmarked,
                            token: auth.token,
                          );
                          setState(() {});
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.chatCircle(),
                        color: Colors.white,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.6,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) {
                              final currentChapter =
                              widget.chapters[_currentChapterIndex];
                              final chapterId = currentChapter is Chapter
                                  ? currentChapter.id
                                  : (currentChapter as LocalChapter).chapterId;

                              return ChangeNotifierProvider(
                                create: (_) => CommentsProvider(),
                                child: CommentsBottomSheet(
                                  scrollController: scrollController,
                                  currentChapterIndex: _currentChapterIndex,
                                  mangaId: widget.manga.id,
                                  chapterId: chapterId,
                                  chapters: widget.chapters,
                                  onChapterChange: (index) {
                                    setState(() {
                                      _currentChapterIndex = index;
                                      _bottomChapterIndex = index;
                                    });
                                    _loadInitialChapter();
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChapterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        disabledColor: Colors.white24,
      ),
    );
  }
}

sealed class _ReaderItem {}

class _ReaderImageItem extends _ReaderItem {
  final int chapterIndex;
  final int pageIndex;
  final dynamic page;

  _ReaderImageItem({
    required this.chapterIndex,
    required this.pageIndex,
    required this.page,
  });
}

class _ReaderChapterSeparatorItem extends _ReaderItem {
  final String previousChapterName;
  final String currentChapterName;

  _ReaderChapterSeparatorItem({
    required this.previousChapterName,
    required this.currentChapterName,
  });
}

class _ChapterSeparator extends StatelessWidget {
  final String previousChapterName;
  final String currentChapterName;

  const _ChapterSeparator({
    required this.previousChapterName,
    required this.currentChapterName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            previousChapterName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 40,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 42),
          const Text(
            'Current:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentChapterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 40,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VerticalBarThumbShape extends SliderComponentShape {
  final double width;
  final double height;
  final Color color;

  const VerticalBarThumbShape({
    this.width = 4.0,
    this.height = 24.0,
    this.color = const Color(0xFF34D399),
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final RRect rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      const Radius.circular(2.0),
    );

    canvas.drawRRect(rRect, paint);
  }
}
