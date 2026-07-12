import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import '../models/local_models.dart';
import '../components/MainNavigationBar.dart';
import '../components/floating_nav_scroll_scope.dart';
import '../models/manga.dart';
import '../providers/auth_provider.dart';
import '../services/sources_api.dart';
import '../theme_provider.dart';
import '../providers/offline_library_provider.dart';
import 'MangaDetailsScreen.dart';
import 'SearchScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;
  final SourcesApi _sourcesApi = SourcesApi();

  late Future<List<Manga>> _popularMangaFuture;

  final String _defaultSourceId = 'manhuatop';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _popularMangaFuture = _sourcesApi
        .getMangaList(_defaultSourceId, 'popular')
        .then((page) => page.mangas);
  }

  Future<List<Manga>> _fetchHistory(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final repo = Provider.of<OfflineLibraryProvider>(
      context,
      listen: false,
    ).mangaRepo;
    final localMangas = await repo.isar
        .collection<LocalManga>()
        .filter()
        .ownerUserIdEqualTo(authProvider.localScopeUserId)
        .lastReadAtIsNotNull()
        .sortByLastReadAtDesc()
        .limit(5)
        .findAll();

    return localMangas
        .map(
          (m) => Manga(
        id: m.mangaId,
        sourceId: m.sourceId,
        title: m.title,
        url: "",
        thumbnailUrl: m.thumbnailUrl ?? "",
        description: m.description ?? "",
        status: m.status ?? "Unknown",
      ),
    )
        .toList();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final offlineLibrary = Provider.of<OfflineLibraryProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color cardColor = isDarkMode
        ? Colors.white10
        : Colors.white.withOpacity(0.5);
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Keihatsu',
          style: GoogleFonts.hennyPenny(
            textStyle: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: Icon(Icons.search_rounded, color: textColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications, color: textColor),
          ),
        ],
      ),
      body: FloatingNavScrollScope(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: brandColor,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Continue Reading Section
              FutureBuilder<List<Manga>>(
                future: _fetchHistory(context),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      _buildSectionHeader(
                        "Continue Reading",
                        textColor,
                        onSeeMore: () {
                          // Navigate to history screen (index 2 in MainNavigationBar)
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const Scaffold(
                                body: Center(child: Text("History")),
                              ), // Temporary, or just switch tab if MainNavigationBar supports it
                            ),
                          );
                          // Actually, MainNavigationBar controls the body. HomePage is just one tab.
                          // Switching tabs requires callback to parent or using a global state for tab index.
                          // For now, let's just push HistoryScreen if available or do nothing/print.
                          // The user said "LIKE history screen".
                          // Let's just navigate to HistoryScreen directly for "See More"
                          Navigator.pushNamed(context, '/history');
                        },
                      ),
                      _buildMangaList(
                        snapshot.data!,
                        brandColor,
                        textColor,
                        cardColor,
                        offlineLibrary,
                        height: 200,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),

              // Latest Update Section
              _buildSectionHeader(
                "Latest Updates",
                textColor,
                onSeeMore: () {
                  Navigator.pushReplacementNamed(context, '/library');
                },
              ),
              _buildFutureMangaList(
                _popularMangaFuture,
                brandColor,
                textColor,
                cardColor,
                offlineLibrary,
                height: 220,
              ),

              const SizedBox(height: 30),

              // Latest Updates Section
              // _buildSectionHeader("Latest Updates", textColor),
              // _buildFutureMangaList(
              //   _latestMangaFuture,
              //   brandColor,
              //   textColor,
              //   cardColor,
              //   offlineLibrary,
              //   height: 200,
              //   compact: true,
              // ),

              // const SizedBox(height: 30),

              // Recommendations (Using Popular for now)
              _buildSectionHeader("You might like", textColor),
              _buildFutureMangaList(
                _popularMangaFuture,
                brandColor,
                textColor,
                cardColor,
                offlineLibrary,
                height: 200,
                compact: true,
                skip: 5,
              ),

              const SizedBox(height: 100), // Space for navigation bar
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        brandColor: brandColor,
      ),
    );
  }

  Widget _buildMangaList(
      List<Manga> mangas,
      Color brandColor,
      Color textColor,
      Color cardColor,
      OfflineLibraryProvider offlineLibrary, {
        required double height,
        bool compact = false,
      }) {
    return SizedBox(
      height: height,
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
            compact: compact,
          );
        },
      ),
    );
  }

  Widget _buildFutureMangaList(
      Future<List<Manga>> future,
      Color brandColor,
      Color textColor,
      Color cardColor,
      OfflineLibraryProvider offlineLibrary, {
        required double height,
        bool compact = false,
        int skip = 0,
      }) {
    return FutureBuilder<List<Manga>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: Center(child: CircularProgressIndicator(color: brandColor)),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: height,
            child: Center(
              child: Icon(PhosphorIcons.warningCircle(), color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: height,
            child: const Center(child: Text("No data found")),
          );
        }

        final mangas = snapshot.data!.skip(skip).toList();
        return _buildMangaList(
          mangas,
          brandColor,
          textColor,
          cardColor,
          offlineLibrary,
          height: height,
          compact: compact,
        );
      },
    );
  }

  Widget _buildSectionHeader(
      String title,
      Color textColor, {
        VoidCallback? onSeeMore,
      }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.hennyPenny(
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          if (onSeeMore != null)
            IconButton(
              onPressed: onSeeMore,
              icon: Icon(
                PhosphorIcons.arrowRight(),
                color: textColor.withOpacity(0.6),
                size: 20,
              ),
            )
          else
            Icon(
              PhosphorIcons.caretRight(),
              color: textColor.withOpacity(0.4),
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildMangaCard(
      BuildContext context,
      Manga manga,
      Color brandColor,
      Color textColor,
      Color cardColor,
      OfflineLibraryProvider offlineLibrary, {
        bool compact = false,
      }) {
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
        width: compact ? 110 : 140,
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
                    if (!compact)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
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
                          child: Icon(
                            PhosphorIcons.bookBookmark(PhosphorIconsStyle.fill),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact)
                    Text(
                      manga.status ?? "Latest",
                      style: TextStyle(
                        fontSize: 11,
                        color: brandColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
