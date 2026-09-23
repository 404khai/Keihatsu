import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga.dart';
import '../models/source.dart';
import '../services/sources_api.dart';
import '../services/sources_repository.dart';
import '../services/source_rollout.dart';
import '../components/ExtensionImage.dart';
import '../components/OfflineImage.dart';
import '../models/local_models.dart';
import '../theme_provider.dart';
import '../providers/offline_library_provider.dart';
import '../components/CustomBackButton.dart';
import 'MangaDetailsScreen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SourcesApi _sourcesApi = SourcesApi();

  List<Source> _sources = [];
  Map<String, List<Manga>> _results = {};
  Map<String, bool> _loadingSources = {};
  Map<String, String> _sourceErrors = {};
  Map<String, bool> _hasNext = {};
  Map<String, int> _pages = {};
  List<LocalSource> _enabledSources = [];
  int _searchGeneration = 0;
  bool _hasSearched = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSources();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> _addToHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList('search_history') ?? [];

      history.remove(query);
      history.insert(0, query);

      if (history.length > 5) {
        history = history.sublist(0, 5);
      }

      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _loadSources() async {
    try {
      final sources = await _sourcesApi.getSources();
      if (!mounted) return;
      final local = await context.read<SourcesRepository>().getSources();
      if (!mounted) return;
      setState(() {
        _sources = sources;
        _enabledSources = local
            .where(
              (source) =>
                  source.enabled && SourceRollout.isAvailable(source.sourceId),
            )
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading sources: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    query = query.trim();
    if (query.isEmpty) return;

    _addToHistory(query);
    await _loadSources();
    if (!mounted) return;
    final generation = ++_searchGeneration;
    final searchSources = _sources
        .where(
          (source) => _enabledSources.any(
            (local) => local.sourceId.toLowerCase() == source.id.toLowerCase(),
          ),
        )
        .toList();

    setState(() {
      _results = {};
      _sourceErrors = {};
      _hasNext = {};
      _pages = {};
      _loadingSources = {for (var s in searchSources) s.id: true};
      _hasSearched = true;
    });

    for (var source in searchSources) {
      _loadPage(source, query, 1, generation);
    }
  }

  Future<void> _loadPage(
    Source source,
    String query,
    int pageNumber,
    int generation,
  ) async {
    try {
      final page = await _sourcesApi.getMangaList(
        source.id,
        'search',
        page: pageNumber,
        q: query,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results[source.id] = [...?_results[source.id], ...page.mangas];
        _hasNext[source.id] = page.hasNextPage;
        _pages[source.id] = pageNumber;
        _sourceErrors.remove(source.id);
        _loadingSources[source.id] = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _sourceErrors[source.id] = 'Could not load ${source.name}';
        _loadingSources[source.id] = false;
      });
    }
  }

  void _loadMore(Source source) {
    if (_loadingSources[source.id] == true) return;
    setState(() => _loadingSources[source.id] = true);
    _loadPage(
      source,
      _searchController.text.trim(),
      (_pages[source.id] ?? 1) + 1,
      _searchGeneration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final offlineLibrary = Provider.of<OfflineLibraryProvider>(context);
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
    final Color cardColor = cs.surfaceContainer;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const CustomBackButton(),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Search manga...',
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            onPressed: () => _performSearch(_searchController.text),
            icon: Icon(Icons.search_rounded, color: textColor),
          ),
        ],
      ),
      body: !_hasSearched
          ? (_searchHistory.isEmpty
                ? _buildEmptyState(textColor)
                : _buildHistoryList(textColor, brandColor))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                if (_loadingSources.values.any((loading) => loading))
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: brandColor),
                    ),
                  ),
                ..._sources
                    .where((source) => _loadingSources.containsKey(source.id))
                    .map(
                      (source) => _buildSourceSection(
                        source,
                        _results[source.id] ?? [],
                        brandColor,
                        textColor,
                        cardColor,
                        offlineLibrary,
                      ),
                    ),
                if (_loadingSources.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Enable an extension to search',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildHistoryList(Color textColor, Color brandColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Recent Searches',
            style: GoogleFonts.unbounded(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: brandColor,
              ),
            ),
          ),
        ),
        ..._searchHistory.map(
          (query) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(query, style: TextStyle(color: textColor)),
            trailing: Icon(
              Icons.arrow_outward_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              _searchController.text = query;
              _performSearch(query);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textColor) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 80,
            color: cs.onSurfaceVariant.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 20),
          Text(
            'Search across all sources',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection(
    Source source,
    List<Manga> mangas,
    Color brandColor,
    Color textColor,
    Color cardColor,
    OfflineLibraryProvider offlineLibrary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              ExtensionImage(
                source: _enabledSources.firstWhere(
                  (local) => local.sourceId == source.id,
                ),
                size: 24,
                borderRadius: 5,
              ),
              const SizedBox(width: 8),
              Text(
                source.name,
                style: GoogleFonts.unbounded(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: brandColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_sourceErrors[source.id] case final error?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(error),
          ),
        if (mangas.isEmpty &&
            _loadingSources[source.id] == false &&
            !_sourceErrors.containsKey(source.id))
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No results'),
          ),
        if (mangas.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: mangas.length,
              itemBuilder: (context, index) {
                final manga = mangas[index];
                return _buildMangaCard(
                  context,
                  manga,
                  brandColor,
                  textColor,
                  cardColor,
                  offlineLibrary,
                );
              },
            ),
          ),
        if (_hasNext[source.id] == true)
          TextButton(
            onPressed: _loadingSources[source.id] == true
                ? null
                : () => _loadMore(source),
            child: Text(
              _loadingSources[source.id] == true
                  ? 'Loading…'
                  : 'More from ${source.name}',
            ),
          ),
      ],
    );
  }

  Widget _buildMangaCard(
    BuildContext context,
    Manga manga,
    Color brandColor,
    Color textColor,
    Color cardColor,
    OfflineLibraryProvider offlineLibrary,
  ) {
    final isInLibrary = offlineLibrary.isInLibrary(manga.id, manga.sourceId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailsScreen(manga: manga),
          ),
        );
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    OfflineImage(
                      imageUrl: manga.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    if (isInLibrary)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                manga.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
