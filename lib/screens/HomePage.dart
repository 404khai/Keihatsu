import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import '../models/local_models.dart';
import '../components/MainNavigationBar.dart';
import '../components/floating_nav_scroll_scope.dart';
import '../components/home/home_updates_section.dart';
import '../components/home/latest_updates_carousel.dart';
import '../components/home/notifications_bottom_sheet.dart';
import '../data/mock_home_updates.dart';
import '../models/manga.dart';
import '../providers/auth_provider.dart';
import '../theme_provider.dart';
import '../providers/offline_library_provider.dart';
import 'MangaDetailsScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;
  // final SourcesApi _sourcesApi = SourcesApi();

  // late Future<List<Manga>> _popularMangaFuture;

  // final String _defaultSourceId = 'manhuatop';

  // @override
  // void initState() {
  //   super.initState();
  //   _loadData();
  // }

  // void _loadData() {
  //   _popularMangaFuture = _sourcesApi
  //       .getMangaList(_defaultSourceId, 'popular')
  //       .then((page) => page.mangas);
  // }

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
    setState(() {});
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
    final Color cardColor = cs.surfaceContainer;
    final Color textColor = cs.onSurface;

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textColor,
            fontSize: 24,
          ),
          // style: GoogleFonts.hennyPenny(
          //   textStyle: TextStyle(
          //     color: textColor,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 24,
          //   ),
          // ),
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SearchScreen()),
          //     );
          //   },
          //   icon: Icon(Icons.search_rounded, color: textColor),
          // ),
          IconButton(
            onPressed: () {
              NotificationsBottomSheet.show(
                context,
                brandColor: brandColor,
                bgColor: backgroundColor,
              );
            },
            icon: Icon(
              Icons.circle_notifications,
              color: textColor,
              size: 32,
            ),
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

              // Latest Updates — M3E carousel
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'You might like',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: textColor,
                    fontSize: 20,
                  ),
                ),
              ),
              LatestUpdatesCarousel(
                brandColor: brandColor,
                textColor: textColor,
                onShowAll: () {
                  Navigator.pushReplacementNamed(context, '/library');
                },
              ),

              // Grouped updates feed
              HomeUpdatesSection(
                brandColor: brandColor,
                textColor: textColor,
                groups: mockHomeUpdates,
                onSeeMore: () {
                  Navigator.pushReplacementNamed(context, '/library');
                },
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

  Widget _buildSectionHeader(
      String title,
      Color textColor, {
        VoidCallback? onSeeMore,
      }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.unbounded(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: textColor,
              fontSize: 24,
            ),
            // style: GoogleFonts.hennyPenny(
            //   textStyle: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.bold,
            //     color: textColor,
            //   ),
            // ),
          ),
          if (onSeeMore != null)
            IconButton(
              onPressed: onSeeMore,
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
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
                                Colors.black.withValues(alpha: 0.8),
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
