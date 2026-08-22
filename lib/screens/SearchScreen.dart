import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga.dart';
import '../models/source.dart';
import '../services/sources_api.dart';
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
  static const String _browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36';
  final TextEditingController _searchController = TextEditingController();
  final SourcesApi _sourcesApi = SourcesApi();

  static const Set<String> _allowedSourceIds = {'manhuatop'};

  List<Source> _sources = [];
  Map<String, List<Manga>> _results = {};
  Map<String, bool> _loadingSources = {};
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
      setState(() {
        _sources = sources;
      });
    } catch (e) {
      debugPrint('Error loading sources: $e');
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    _addToHistory(query);

    final searchSources = _sources
        .where((s) => _allowedSourceIds.contains(s.id.toLowerCase()))
        .toList();

    setState(() {
      _results = {};
      _loadingSources = {for (var s in searchSources) s.id: true};
      _hasSearched = true;
    });

    for (var source in searchSources) {
      _sourcesApi
          .getMangaList(source.id, 'search', q: query)
          .then((page) {
        if (mounted) {
          setState(() {
            if (page.mangas.isNotEmpty) {
              _results[source.name] = page.mangas;
            }
            _loadingSources[source.id] = false;
          });
        }
      })
          .catchError((e) {
        if (mounted) {
          setState(() {
            _loadingSources[source.id] = false;
          });
        }
      });
    }
  }

  Map<String, String>? _buildImageHeaders(Manga manga) {
    if (manga.sourceId.toLowerCase() != 'batcave') {
      return null;
    }

    return {
      'User-Agent': _browserUserAgent,
      'Referer': manga.url,
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };
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
          ..._results.entries.map(
                (entry) => _buildSourceSection(
              entry.key,
              entry.value,
              brandColor,
              textColor,
              cardColor,
              offlineLibrary,
            ),
          ),
          if (!_loadingSources.values.any((loading) => loading) &&
              _results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No results found',
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
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection(
      String sourceName,
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
          child: Text(
            sourceName,
            style: GoogleFonts.unbounded(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: brandColor,
              ),
            ),
          ),
        ),
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
                    Image.network(
                      manga.thumbnailUrl,
                      headers: _buildImageHeaders(manga),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
