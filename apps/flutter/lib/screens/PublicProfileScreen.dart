import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../components/CustomBackButton.dart';
import '../components/keihatsu_refresh_indicator.dart';
import '../components/user_blobatar.dart';
import '../models/user.dart';
import '../services/auth_api.dart';
import '../services/sources_repository.dart';
import '../theme_provider.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String fallbackUsername;
  final String? fallbackAvatarUrl;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.fallbackUsername,
    this.fallbackAvatarUrl,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<PublicProfile> _profileFuture;
  late ScrollController _scrollController;
  bool _isGridView = false;
  bool _showTitle = false;
  Map<String, String> _sourceNames = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 120) {
        if (!_showTitle) {
          setState(() => _showTitle = true);
        }
      } else if (_showTitle) {
        setState(() => _showTitle = false);
      }
    });
    _profileFuture = AuthApi().getPublicProfile(widget.userId);
    _loadSourceNames();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSourceNames() async {
    final sourcesRepo = Provider.of<SourcesRepository>(context, listen: false);
    final sources = await sourcesRepo.getSources();
    if (!mounted) return;

    setState(() {
      _sourceNames = {
        for (final source in sources) source.sourceId: source.name,
      };
    });
  }

  Future<void> _refreshProfile() async {
    final future = AuthApi().getPublicProfile(widget.userId);
    setState(() {
      _profileFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final isDarkMode = themeProvider.isDarkTheme;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<PublicProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.warningCircle(),
                      size: 40,
                      color: textColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load this profile',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _refreshProfile,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return KeihatsuRefreshIndicator(
            onRefresh: _refreshProfile,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: bgColor,
                  elevation: 0,
                  leading: _showTitle ? const CustomBackButton() : null,
                  title: _showTitle
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.transparent,
                              child: ClipOval(child: _buildAvatar(profile, 32)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                profile.username,
                                style: GoogleFonts.denkOne(
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4),
                              BlendMode.darken,
                            ),
                            child: _buildBanner(profile.bannerUrl),
                          ),
                        ),
                        if (!_showTitle)
                          const SafeArea(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: CustomBackButton(),
                            ),
                          ),
                        Positioned(
                          bottom: 10,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildAvatar(profile, 100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.username,
                            style: GoogleFonts.hennyPenny(
                              textStyle: TextStyle(
                                color: textColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.bio?.trim().isNotEmpty == true
                                ? profile.bio!.trim()
                                : 'No bio available',
                            style: TextStyle(
                              color: textColor.withOpacity(0.75),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                PhosphorIcons.calendarDots(),
                                size: 16,
                                color: textColor.withOpacity(0.45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                profile.createdAt != null
                                    ? 'Member since ${profile.createdAt!.year}'
                                    : 'Keihatsu member',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.45),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  '${profile.stats?.libraryCount ?? 0}',
                                  'In Library',
                                  textColor,
                                ),
                                _buildDivider(textColor),
                                _buildStatItem(
                                  _formatReadingTime(
                                    profile.stats?.totalReadingTimeMinutes ?? 0,
                                  ),
                                  'Reading',
                                  textColor,
                                ),
                                _buildDivider(textColor),
                                _buildStatItem(
                                  '${profile.stats?.commentsCount ?? 0}',
                                  'Comments',
                                  textColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Library (${profile.stats?.libraryCount ?? profile.library.length})',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                                icon: Icon(
                                  _isGridView
                                      ? PhosphorIcons.list()
                                      : PhosphorIcons.squaresFour(),
                                  color: brandColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!profile.isProfilePublic)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              PhosphorIcons.lock(),
                              size: 40,
                              color: textColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "This user's library is not public",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (profile.library.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              PhosphorIcons.books(),
                              size: 40,
                              color: textColor.withOpacity(0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No manhwas in this library yet',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = profile.library[index];
                        return _buildGridItem(
                          entry,
                          textColor,
                          brandColor,
                          cardColor,
                        );
                      }, childCount: profile.library.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = profile.library[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildListItem(
                            entry,
                            textColor,
                            brandColor,
                            cardColor,
                          ),
                        );
                      }, childCount: profile.library.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String? bannerUrl) {
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      return Image.network(
        bannerUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('images/profileBg.jpeg', fit: BoxFit.cover),
      );
    }

    return Image.asset('images/profileBg.jpeg', fit: BoxFit.cover);
  }

  Widget _buildAvatar(PublicProfile profile, double size) {
    return UserBlobatar(
      seed: profile.id,
      label: profile.username,
      size: size,
      hue: profile.avatarHue,
      shape: profile.avatarShape,
      expression: profile.avatarExpression,
      animated: profile.avatarAnimated,
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider(Color textColor) {
    return Container(height: 38, width: 1, color: textColor.withOpacity(0.1));
  }

  Widget _buildListItem(
    PublicLibraryEntry entry,
    Color textColor,
    Color brandColor,
    Color cardColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCover(entry.thumbnailUrl, width: 82, height: 118),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.author?.trim().isNotEmpty == true
                      ? entry.author!
                      : 'Unknown author',
                  style: TextStyle(
                    color: textColor.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(
                      PhosphorIcons.globe(),
                      _sourceNames[entry.sourceId] ?? entry.sourceId,
                      textColor,
                      brandColor,
                    ),
                    _buildMetaChip(
                      PhosphorIcons.bookOpen(),
                      '${entry.totalChapters} chapters',
                      textColor,
                      brandColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    PublicLibraryEntry entry,
    Color textColor,
    Color brandColor,
    Color cardColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: _buildCover(entry.thumbnailUrl, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.author?.trim().isNotEmpty == true
                      ? entry.author!
                      : 'Unknown author',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _sourceNames[entry.sourceId] ?? entry.sourceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: brandColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(
    IconData icon,
    String text,
    Color textColor,
    Color brandColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: brandColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: brandColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(String? thumbnailUrl, {double? width, double? height}) {
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Image.network(
        thumbnailUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade900,
          child: const Icon(Icons.broken_image, color: Colors.white24),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade900,
      child: const Icon(Icons.menu_book, color: Colors.white24),
    );
  }

  String _formatReadingTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }

    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}
