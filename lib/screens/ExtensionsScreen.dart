import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../components/AppToast.dart';
import '../components/MainNavigationBar.dart';
import '../models/local_models.dart';
import '../services/sources_repository.dart';
import '../theme_provider.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen>
    with SingleTickerProviderStateMixin {
  final int _currentIndex = 3;
  late Future<List<LocalSource>> _sourcesFuture;
  String _searchQuery = '';
  late TabController _tabController;

  static const Set<String> _availableSourceIds = {'manhuatop'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSources({bool forceRefresh = false}) {
    final repo = Provider.of<SourcesRepository>(context, listen: false);
    setState(() {
      _sourcesFuture = _loadAndNormalizeSources(
        repo,
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<List<LocalSource>> _loadAndNormalizeSources(
      SourcesRepository repo, {
        bool forceRefresh = false,
      }) async {
    final sources = await repo.getSources(forceRefresh: forceRefresh);

    for (final source in sources) {
      if (!_isSourceAvailable(source) && source.enabled) {
        await repo.toggleSource(source.sourceId, false);
      }
    }

    return repo.getSources();
  }

  Future<void> _handleSourceToggle(
      SourcesRepository repo,
      LocalSource source,
      bool value,
      ) async {
    final isAvailable = _isSourceAvailable(source);

    if (!isAvailable) {
      if (value && mounted) {
        AppToast.show(
          context,
          message: 'Coming soon',
          type: AppToastType.warning,
        );
      }

      if (source.enabled) {
        await repo.toggleSource(source.sourceId, false);
        _loadSources();
      }
      return;
    }

    await repo.toggleSource(source.sourceId, value);
    _loadSources();
  }

  bool _isSourceAvailable(LocalSource source) {
    return _availableSourceIds.contains(source.sourceId.toLowerCase());
  }

  Widget _buildFallbackIcon(LocalSource source, Color brandColor) {
    if (source.iconLocalPath != null) {
      return Image.file(
        File(source.iconLocalPath!),
        fit: BoxFit.cover,
        color: _isSourceAvailable(source) && source.enabled
            ? null
            : Colors.grey,
        colorBlendMode: _isSourceAvailable(source) && source.enabled
            ? null
            : BlendMode.saturation,
        errorBuilder: (context, error, stackTrace) =>
            Icon(PhosphorIcons.puzzlePiece(), color: brandColor),
      );
    } else if (source.iconUrl != null) {
      return Image.network(
        source.iconUrl!,
        fit: BoxFit.cover,
        color: _isSourceAvailable(source) && source.enabled
            ? null
            : Colors.grey,
        colorBlendMode: _isSourceAvailable(source) && source.enabled
            ? null
            : BlendMode.saturation,
        errorBuilder: (context, error, stackTrace) =>
            Icon(PhosphorIcons.puzzlePiece(), color: brandColor),
      );
    } else {
      return Icon(PhosphorIcons.puzzlePiece(), color: brandColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode
        ? Colors.white10
        : Colors.white.withOpacity(0.5);
    final repo = Provider.of<SourcesRepository>(context, listen: false);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Extensions',
          style: GoogleFonts.unbounded(
            // textStyle: tt.titleLarge,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textColor,
            fontSize: 24
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
          IconButton(
            onPressed: () => _loadSources(forceRefresh: true),
            icon: Icon(PhosphorIcons.arrowsClockwise(), color: textColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildTabBar(brandColor, textColor, cardColor),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSourcesTab(brandColor, textColor, cardColor, repo),
                _buildPluginStoreTab(brandColor, textColor, cardColor, repo),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        brandColor: brandColor,
      ),
    );
  }

  Widget _buildSourcesTab(
      Color brandColor,
      Color textColor,
      Color cardColor,
      SourcesRepository repo,
      ) {
    return FutureBuilder<List<LocalSource>>(
      future: _sourcesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: brandColor));
        } else if (snapshot.hasError) {
          return _buildErrorWidget(brandColor, textColor);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(textColor);
        }

        final sources = snapshot.data!;
        final installedSources = sources.where((s) => s.enabled).toList();
        installedSources.sort((a, b) {
          final pinnedA = a.pinned ? 0 : 1;
          final pinnedB = b.pinned ? 0 : 1;
          if (pinnedA != pinnedB) return pinnedA.compareTo(pinnedB);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        final filteredSources = _filterSources(installedSources);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSearchField(brandColor, textColor, cardColor),
            const SizedBox(height: 20),
            ...filteredSources.map(
                  (source) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSourceCard(
                  source,
                  brandColor,
                  textColor,
                  cardColor,
                  repo,
                  showPin: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPluginStoreTab(
      Color brandColor,
      Color textColor,
      Color cardColor,
      SourcesRepository repo,
      ) {
    return FutureBuilder<List<LocalSource>>(
      future: _sourcesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: brandColor));
        } else if (snapshot.hasError) {
          return _buildErrorWidget(brandColor, textColor);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(textColor);
        }

        final sources = snapshot.data!;
        sources.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        final filteredSources = _filterSources(sources);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSearchField(brandColor, textColor, cardColor),
            const SizedBox(height: 20),
            ...filteredSources.map(
                  (source) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSourceCard(
                  source,
                  brandColor,
                  textColor,
                  cardColor,
                  repo,
                  showPin: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<LocalSource> _filterSources(List<LocalSource> sources) {
    if (_searchQuery.trim().isEmpty) {
      return sources;
    }
    final query = _searchQuery.toLowerCase();
    return sources.where((source) {
      return source.name.toLowerCase().contains(query) ||
          source.sourceId.toLowerCase().contains(query) ||
          source.baseUrl.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildErrorWidget(Color brandColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warningCircle(), size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load extensions',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          TextButton(
            onPressed: () => _loadSources(),
            child: Text('Retry', style: TextStyle(color: brandColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color brandColor, Color textColor, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: textColor.withOpacity(0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: brandColor.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        labelColor: brandColor,
        unselectedLabelColor: textColor.withOpacity(0.6),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(height: 40, child: Center(child: Text('Sources'))),
          Tab(height: 40, child: Center(child: Text('Plugin Store'))),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(Color textColor) {
    return Center(
      child: Text(
        'No extensions found',
        style: TextStyle(color: textColor.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildSearchField(Color brandColor, Color textColor, Color cardColor) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: TextStyle(color: textColor),
      cursorColor: brandColor,
      decoration: InputDecoration(
        hintText: 'Search extensions',
        hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
        prefixIcon: Icon(
          PhosphorIcons.magnifyingGlass(),
          color: textColor.withOpacity(0.45),
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: brandColor.withOpacity(0.35)),
        ),
      ),
    );
  }

  Widget _buildSourceCard(
      LocalSource source,
      Color brandColor,
      Color textColor,
      Color cardColor,
      SourcesRepository repo, {
        bool showPin = true,
      }) {
    final isAvailable = _isSourceAvailable(source);
    final isEnabled = isAvailable && source.enabled;

    // Map of source IDs to local image assets
    final Map<String, String> extensionImages = {
      'atsumaru': 'images/extensions/atsumaru.png',
      'batcave': 'images/extensions/batcave.png',
      'manhuatop': 'images/extensions/manhuatop.jpeg',
      'weebcentral': 'images/extensions/weebcentral.png',
      'mangafire': 'images/extensions/mangafire.png',
    };

    final imagePath = extensionImages[source.sourceId.toLowerCase()];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? cardColor : cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imagePath != null
                  ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                color: isEnabled ? null : Colors.grey,
                colorBlendMode: isEnabled ? null : BlendMode.saturation,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackIcon(source, brandColor),
              )
                  : _buildFallbackIcon(source, brandColor),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? textColor : textColor.withOpacity(0.4),
                  ),
                ),
                Text(
                  '${source.lang.toUpperCase()} • ${source.baseUrl}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? textColor.withOpacity(0.6)
                        : textColor.withOpacity(0.2),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  isAvailable ? 'Available now' : 'Coming soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? brandColor
                        : textColor.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
          if (showPin)
            IconButton(
              onPressed: () async {
                await repo.pinSource(source.sourceId, !source.pinned);
                _loadSources();
              },
              icon: Icon(
                source.pinned
                    ? PhosphorIcons.pushPin(PhosphorIconsStyle.fill)
                    : PhosphorIcons.pushPin(),
                color: source.pinned ? brandColor : textColor.withOpacity(0.3),
                size: 20,
              ),
            ),
          Switch(
            value: isEnabled,
            activeColor: brandColor,
            onChanged: (val) async {
              await _handleSourceToggle(repo, source, val);
            },
          ),
        ],
      ),
    );
  }
}
