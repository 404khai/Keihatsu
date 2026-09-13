import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/ExtensionImage.dart';
import '../components/OfflineImage.dart';
import '../models/local_models.dart';
import '../models/manga.dart';
import '../providers/offline_library_provider.dart';
import '../services/sources_repository.dart';
import '../theme_provider.dart';
import 'MangaDetailsScreen.dart';

enum ExtensionBrowseLayout {
  comfortable('Comfortable grid', Icons.grid_view_rounded),
  compact('Compact grid', Icons.grid_on_rounded),
  list('List', Icons.view_list_rounded);

  const ExtensionBrowseLayout(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ExtensionBrowseScreen extends StatefulWidget {
  const ExtensionBrowseScreen({super.key, required this.source});

  final LocalSource source;

  @override
  State<ExtensionBrowseScreen> createState() => _ExtensionBrowseScreenState();
}

class _ExtensionBrowseScreenState extends State<ExtensionBrowseScreen> {
  static const int _columns = 3;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<Manga> _mangas = [];
  ExtensionBrowseLayout _layout = ExtensionBrowseLayout.comfortable;
  Timer? _searchDebounce;
  bool _isLoading = false;
  bool _hasNextPage = true;
  String? _error;
  int _page = 0;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_loadMoreNearEnd)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (_scrollController.position.extentAfter < 700) {
      _loadNextPage();
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _reload() async {
    final generation = ++_requestGeneration;
    setState(() {
      _mangas.clear();
      _page = 0;
      _hasNextPage = true;
      _error = null;
      _isLoading = false;
    });
    await _loadNextPage(generation: generation);
  }

  Future<void> _loadNextPage({int? generation}) async {
    if (_isLoading || !_hasNextPage) return;
    final requestGeneration = generation ?? _requestGeneration;
    final query = _searchController.text.trim();
    final nextPage = _page + 1;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = Provider.of<SourcesRepository>(context, listen: false);
      final result = await repository.getMangaList(
        widget.source.sourceId,
        query.isEmpty ? 'popular' : 'search',
        page: nextPage,
        query: query.isEmpty ? null : query,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;
      final known = _mangas
          .map((manga) => '${manga.sourceId}\u0000${manga.id}')
          .toSet();
      setState(() {
        _mangas.addAll(
          result.mangas.where(
            (manga) => known.add('${manga.sourceId}\u0000${manga.id}'),
          ),
        );
        _page = nextPage;
        _hasNextPage = result.hasNextPage;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) _loadMoreNearEnd();
      });
    } catch (error) {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted && requestGeneration == _requestGeneration) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSourceWebsite() async {
    final uri = Uri.tryParse(widget.source.baseUrl);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the extension website.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final library = Provider.of<OfflineLibraryProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isPureBlack =
        themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme;
    final backgroundColor = isPureBlack ? Colors.black : colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            ExtensionImage(source: widget.source, size: 34, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.source.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.unbounded(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSourceWebsite,
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
          PopupMenuButton<ExtensionBrowseLayout>(
            initialValue: _layout,
            tooltip: 'Change appearance',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (layout) => setState(() => _layout = layout),
            itemBuilder: (context) => ExtensionBrowseLayout.values
                .map(
                  (layout) => PopupMenuItem(
                    value: layout,
                    child: Row(
                      children: [
                        Icon(layout.icon, size: 20),
                        const SizedBox(width: 12),
                        Text(layout.label),
                        if (_layout == layout) ...[
                          const Spacer(),
                          Icon(Icons.check_rounded, color: colorScheme.primary),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        child: SearchBar(
          controller: _searchController,
          hintText: 'Search ${widget.source.name}',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  _reload();
                },
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
              ),
          ],
          onChanged: _onSearchChanged,
          onSubmitted: (_) => _reload(),
          textInputAction: TextInputAction.search,
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainer),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          elevation: const WidgetStatePropertyAll(3),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_mangas.isEmpty && _isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_mangas.isEmpty && _error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _BrowseMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Could not load manga',
                  message: _error!,
                  actionLabel: 'Retry',
                  onAction: _reload,
                ),
              )
            else if (_mangas.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _BrowseMessage(
                  icon: Icons.menu_book_rounded,
                  title: 'No manga found',
                  message: 'Try a different search.',
                ),
              )
            else
              ..._contentSlivers(library),
            if (_mangas.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : _error == null
                        ? const SizedBox.shrink()
                        : TextButton.icon(
                            onPressed: _loadNextPage,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry loading more'),
                          ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(OfflineLibraryProvider library) {
    if (_layout == ExtensionBrowseLayout.list) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: _mangas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _MangaListCard(
              manga: _mangas[index],
              isInLibrary: library.isInLibrary(
                _mangas[index].id,
                _mangas[index].sourceId,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
            childAspectRatio: 0.58,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _MangaGridCard(
              manga: _mangas[index],
              layout: _layout,
              isInLibrary: library.isInLibrary(
                _mangas[index].id,
                _mangas[index].sourceId,
              ),
            ),
            childCount: _mangas.length,
          ),
        ),
      ),
    ];
  }
}

class _MangaGridCard extends StatelessWidget {
  const _MangaGridCard({
    required this.manga,
    required this.layout,
    required this.isInLibrary,
  });

  final Manga manga;
  final ExtensionBrowseLayout layout;
  final bool isInLibrary;

  @override
  Widget build(BuildContext context) {
    final compact = layout == ExtensionBrowseLayout.compact;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MangaDetailsScreen(manga: manga)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OfflineImage(
                    imageUrl: manga.thumbnailUrl,
                    cacheKey: '${manga.sourceId}:${manga.id}',
                  ),
                  if (compact)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xE6000000)],
                        ),
                      ),
                    ),
                  if (isInLibrary) ...[
                    const ColoredBox(color: Color(0x73000000)),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: _LibraryMarker(),
                    ),
                  ],
                  if (compact)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          manga.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
              child: Text(
                manga.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MangaListCard extends StatelessWidget {
  const _MangaListCard({required this.manga, required this.isInLibrary});

  final Manga manga;
  final bool isInLibrary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MangaDetailsScreen(manga: manga)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 84,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OfflineImage(
                        imageUrl: manga.thumbnailUrl,
                        cacheKey: '${manga.sourceId}:${manga.id}',
                      ),
                      if (isInLibrary) ...[
                        const ColoredBox(color: Color(0x73000000)),
                        const Align(
                          alignment: Alignment.topLeft,
                          child: _LibraryMarker(compact: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      manga.author?.trim().isNotEmpty == true
                          ? manga.author!
                          : manga.status ?? widgetFallback,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static const widgetFallback = 'Manga';
}

class _LibraryMarker extends StatelessWidget {
  const _LibraryMarker({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(compact ? 4 : 7),
      padding: EdgeInsets.all(compact ? 4 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB36B),
        borderRadius: BorderRadius.circular(compact ? 5 : 7),
      ),
      child: Icon(
        Icons.library_books_rounded,
        size: compact ? 13 : 16,
        color: const Color(0xFF38200E),
      ),
    );
  }
}

class _BrowseMessage extends StatelessWidget {
  const _BrowseMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
