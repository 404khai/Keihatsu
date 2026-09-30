import 'dart:async';
import 'package:isar/isar.dart';
import '../models/local_models.dart';
import '../models/reading_statistics.dart';
import '../providers/auth_provider.dart';
import '../services/manga_repository.dart';
import '../services/history_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedFilter = 'Last Week';
  final List<String> _filters = [
    'Last Week',
    'Last Month',
    'Last Year',
    'All Time',
  ];

  List<LocalChapter> _chapters = [];
  List<LocalManga> _mangas = [];
  String? _owner;
  String? _error;
  bool _loading = true;
  int _loadGeneration = 0;
  StreamSubscription<void>? _chapterSubscription;
  StreamSubscription<void>? _mangaSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final owner = auth.localScopeUserId;
    if (_owner == owner) return;
    _owner = owner;
    _chapters = [];
    _mangas = [];
    _error = null;
    _loading = true;
    _chapterSubscription?.cancel();
    _mangaSubscription?.cancel();
    final isar = context.read<MangaRepository>().isar;
    _chapterSubscription = isar.collection<LocalChapter>().watchLazy().listen(
      (_) => _loadLocal(),
    );
    _mangaSubscription = isar.collection<LocalManga>().watchLazy().listen(
      (_) => _loadLocal(),
    );
    _loadLocal();
    unawaited(_refresh());
  }

  Future<void> _loadLocal() async {
    final generation = ++_loadGeneration;
    final owner = _owner;
    final isar = context.read<MangaRepository>().isar;
    try {
      final chapters = await isar
          .collection<LocalChapter>()
          .filter()
          .ownerUserIdEqualTo(owner!)
          .lastReadAtIsNotNull()
          .findAll();
      final mangas = await isar
          .collection<LocalManga>()
          .filter()
          .ownerUserIdEqualTo(owner)
          .findAll();
      if (!mounted || _owner != owner || generation != _loadGeneration) return;
      setState(() {
        _chapters = chapters;
        _mangas = mangas;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _owner != owner || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = 'Could not load reading history.';
      });
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final owner = _owner;
    final token = auth.token;
    final repository = context.read<HistoryRepository>();
    try {
      if (token != null) {
        await Future.wait([
          repository.refreshHistoryFromServer(token, ownerUserId: owner),
          auth.refreshUserStats(),
        ]);
      }
      if (!mounted || _owner != owner) return;
      setState(() {
        _error = null;
      });
    } catch (_) {
      if (!mounted || _owner != owner) return;
      setState(() {
        _error = 'Could not refresh stats. Showing saved data.';
      });
    }
    if (mounted && _owner == owner) await _loadLocal();
  }

  @override
  void dispose() {
    _chapterSubscription?.cancel();
    _mangaSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().user?.stats;
    final stats = ReadingStatistics.calculate(
      chapters: _chapters,
      mangas: _mangas,
      period: _selectedFilter,
      account: account,
    );
    final maxMinutes = stats.activity.fold(
      1.0,
      (value, day) => day.minutes > value ? day.minutes : value,
    );
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brandColor = themeProvider.brandColor;
    final bgColor = themeProvider.effectiveBgColor;
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = isDarkMode
        ? Colors.white10
        : Colors.white.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Statistics',
          style: GoogleFonts.unbounded(
            textStyle: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                icon: Icon(
                  PhosphorIcons.caretDown(),
                  color: textColor,
                  size: 16,
                ),
                dropdownColor: bgColor,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
                items: _filters.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                TextButton(onPressed: _refresh, child: Text(_error!)),
              if (!_loading && stats.activeDays == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Start reading to build your stats.',
                    style: TextStyle(color: textColor),
                  ),
                ),
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Reading Time",
                      "${(stats.readingMinutes / 60).toStringAsFixed(1)}h",
                      PhosphorIcons.clock(),
                      brandColor,
                      cardColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSummaryCard(
                      "Titles Read",
                      "${stats.titlesOpened}",
                      PhosphorIcons.bookOpen(),
                      brandColor,
                      cardColor,
                      textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Comments (all time)",
                      "${account?.commentsCount ?? 0}",
                      PhosphorIcons.chatCircleText(),
                      brandColor,
                      cardColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildSummaryCard(
                      "Chapters read",
                      "${stats.chaptersRead}",
                      PhosphorIcons.listBullets(),
                      brandColor,
                      cardColor,
                      textColor,
                    ),
                  ),
                ],
              ),

              if (account != null)
                Text(
                  'All time: ${(account.totalReadingTimeMinutes / 60).toStringAsFixed(1)}h',
                  style: TextStyle(color: textColor),
                ),
              if (account != null &&
                  account.dailyReadingTimeMinutes.isEmpty &&
                  account.totalReadingTimeMinutes > 0)
                Text(
                  'Daily reading time is unavailable. Pull to refresh.',
                  style: TextStyle(color: textColor),
                ),
              if (account == null)
                Text(
                  'Sign in to load reading time and comments.',
                  style: TextStyle(color: textColor),
                ),
              const SizedBox(height: 30),

              // Bar Chart Section
              Text(
                "Reading Time (UTC)",
                style: GoogleFonts.unbounded(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(stats.activity.length, (
                            index,
                          ) {
                            final day = stats.activity[index];
                            return SizedBox(
                              width: 40,
                              child: Tooltip(
                                message:
                                    "${day.label}: ${day.minutes.toStringAsFixed(1)} min",
                                child: _buildBar(
                                  day.minutes / maxMinutes * 6,
                                  day.label,
                                  brandColor,
                                  textColor,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Recently Finished
              Text(
                "Top Genres",
                style: GoogleFonts.unbounded(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (stats.genres.isEmpty)
                Text(
                  'No completed chapters yet.',
                  style: TextStyle(color: textColor),
                ),
              for (final genre in stats.genres.entries)
                _buildGenreStats(
                  genre.key,
                  genre.value,
                  brandColor,
                  cardColor,
                  textColor,
                ),
              Text(
                'Completed chapters may have multiple genres. Unknown means genre metadata is unavailable.',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    PhosphorIconData icon,
    Color brandColor,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.denkOne(
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    double value,
    String label,
    Color brandColor,
    Color textColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: value * 25, // Scale the height
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGenreStats(
    String genre,
    double percent,
    Color brandColor,
    Color cardColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                genre,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(percent * 100).toInt()}%",
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: cardColor,
              color: brandColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
