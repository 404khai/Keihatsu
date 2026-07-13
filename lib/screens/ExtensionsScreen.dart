import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../common/coming_soon.dart';
import '../components/MainNavigationBar.dart';
import '../components/floating_nav_scroll_scope.dart';
import '../components/gradient_fade_app_bar.dart';
import '../components/library/filter_tabs.dart';
import '../models/local_models.dart';
import '../services/sources_repository.dart';
import '../theme_provider.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen>
    with SingleTickerProviderStateMixin, GradientFadeAppBarMixin {
  static const List<String> _tabIds = ['sources', 'plugin_store', 'migrate'];

  final int _currentIndex = 3;
  late Future<List<LocalSource>> _sourcesFuture;
  String _searchQuery = '';
  late TabController _tabController;
  String _selectedTab = 'sources';

  static const Set<String> _availableSourceIds = {'manhuatop'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabIds.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSources();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final String tabId = _tabIds[_tabController.index];
    if (tabId != _selectedTab) {
      setState(() => _selectedTab = tabId);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _selectTab(String? tabId) {
    if (tabId == null) return;
    final int index = _tabIds.indexOf(tabId);
    if (index < 0) return;
    setState(() => _selectedTab = tabId);
    _tabController.animateTo(index);
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
        ComingSoon.show(context);
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final brandColor = themeProvider.brandColor;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color backgroundColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surface;
    final Color appBarColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surfaceContainer;
    final Color textColor = isDarkTheme ? Colors.white : Colors.black87;
    final Color cardColor = cs.surfaceContainer;
    final repo = Provider.of<SourcesRepository>(context, listen: false);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      appBar: GradientFadeAppBar(
        baseColor: appBarColor,
        fadeAmount: appBarFade,
        automaticallyImplyLeading: false,
        title: Text(
          'Extensions',
          style: GoogleFonts.unbounded(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: textColor,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _loadSources(forceRefresh: true),
            icon: Icon(PhosphorIcons.arrowsClockwise(), color: textColor),
          ),
        ],
      ),
      body: GradientFadeScrollListener(
        onFadeChanged: updateAppBarFade,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilterTabs(
                scrollable: true,
                large: true,
                height: 56,
                tabs: [
                  FilterTab(
                    value: 'sources',
                    label: 'Sources',
                    accent: brandColor,
                    onAccent: cs.onPrimary,
                    icon: Icons.extension_outlined,
                  ),
                  FilterTab(
                    value: 'plugin_store',
                    label: 'Plugins',
                    accent: brandColor,
                    onAccent: cs.onPrimary,
                    icon: Icons.storefront_outlined,
                  ),
                  FilterTab(
                    value: 'migrate',
                    label: 'Migrate',
                    accent: brandColor,
                    onAccent: cs.onPrimary,
                    icon: Icons.swap_horiz_rounded,
                  ),
                ],
                selected: _selectedTab,
                onSelected: _selectTab,
              ),
            ),
            Expanded(
              child: FloatingNavScrollScope(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSourcesTab(brandColor, textColor, cardColor, repo, cs, tt),
                    _buildPluginStoreTab(
                      brandColor,
                      textColor,
                      cardColor,
                      repo,
                      cs,
                      tt,
                    ),
                    _buildMigrateTab(textColor, cardColor, cs, tt),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    ColorScheme cs,
    TextTheme tt,
  ) {
    return FutureBuilder<List<LocalSource>>(
      future: _sourcesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: brandColor));
        } else if (snapshot.hasError) {
          return _buildErrorWidget(brandColor, textColor);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(textColor, tt);
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
            _buildSearchField(brandColor, textColor, cardColor, cs),
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
                  cs,
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
    ColorScheme cs,
    TextTheme tt,
  ) {
    return FutureBuilder<List<LocalSource>>(
      future: _sourcesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: brandColor));
        } else if (snapshot.hasError) {
          return _buildErrorWidget(brandColor, textColor);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget(textColor, tt);
        }

        final sources = snapshot.data!;
        sources.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        final filteredSources = _filterSources(sources);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSearchField(brandColor, textColor, cardColor, cs),
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
                  cs,
                  showPin: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMigrateTab(
    Color textColor,
    Color cardColor,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Material(
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 32,
                  color: cs.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Migrate library',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import your manga library from another reader app. '
                  'Supports backup files and extension migrations.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ComingSoon.show(context),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose backup file'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ComingSoon.show(context),
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Migration guide'),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildEmptyWidget(Color textColor, TextTheme tt) {
    return Center(
      child: Text(
        'No extensions found',
        style: tt.bodyLarge?.copyWith(
          color: textColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSearchField(
    Color brandColor,
    Color textColor,
    Color cardColor,
    ColorScheme cs,
  ) {
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
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: cs.onSurfaceVariant,
        ),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: brandColor.withValues(alpha: 0.35)),
        ),
      ),
    );
  }

  Widget _buildSourceCard(
    LocalSource source,
    Color brandColor,
    Color textColor,
    Color cardColor,
    SourcesRepository repo,
    ColorScheme cs, {
    bool showPin = true,
  }) {
    final isAvailable = _isSourceAvailable(source);
    final isEnabled = isAvailable && source.enabled;

    final Map<String, String> extensionImages = {
      'atsumaru': 'images/extensions/atsumaru.png',
      'batcave': 'images/extensions/batcave.png',
      'manhuatop': 'images/extensions/manhuatop.jpeg',
      'weebcentral': 'images/extensions/weebcentral.png',
      'mangafire': 'images/extensions/mangafire.png',
    };

    final imagePath = extensionImages[source.sourceId.toLowerCase()];

    return Material(
      color: isEnabled ? cardColor : cardColor.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        color: isEnabled ? null : Colors.grey,
                        colorBlendMode:
                            isEnabled ? null : BlendMode.saturation,
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
                      color: isEnabled
                          ? textColor
                          : textColor.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    '${source.lang.toUpperCase()} • ${source.baseUrl}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? cs.onSurfaceVariant
                          : textColor.withValues(alpha: 0.2),
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
                          : textColor.withValues(alpha: 0.35),
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
                  color: source.pinned
                      ? brandColor
                      : textColor.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            Switch(
              value: isEnabled,
              activeThumbColor: brandColor,
              onChanged: (val) async {
                await _handleSourceToggle(repo, source, val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
