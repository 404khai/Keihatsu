import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keihatsu/components/CustomBackButton.dart';
import 'package:keihatsu/components/keihatsu_refresh_indicator.dart';
import 'package:keihatsu/data/mock_updates_feed.dart';
import 'package:keihatsu/screens/UpcomingCalendarScreen.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:material_shapes/material_shapes.dart';
import 'package:provider/provider.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isDarkTheme = themeProvider.isDarkTheme;
    final Color backgroundColor = themeProvider.pureBlackDarkMode && isDarkTheme
        ? Colors.black
        : cs.surface;
    final Color textColor = cs.onSurface;
    final Color mutedColor = cs.onSurfaceVariant;
    final Color brandColor = themeProvider.brandColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: KeihatsuRefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: backgroundColor,
                surfaceTintColor: Colors.transparent,
                leading: const CustomBackButton(),
                leadingWidth: 56,
                title: Text(
                  'Updates',
                  style: GoogleFonts.unbounded(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: textColor,
                    fontSize: 24,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.filter_list_rounded, color: textColor),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const UpcomingCalendarScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.calendar_month_outlined, color: textColor),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Last updated 14hrs ago',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final UpdatesDayGroup group in mockUpdatesFeed) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(group.date),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final MangaUpdateChapter chapter = group.chapters[index];
                      return _UpdateChapterRow(
                        chapter: chapter,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        brandColor: brandColor,
                        iconColor: cs.onSurfaceVariant,
                      );
                    },
                    childCount: group.chapters.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateChapterRow extends StatelessWidget {
  const _UpdateChapterRow({
    required this.chapter,
    required this.textColor,
    required this.mutedColor,
    required this.brandColor,
    required this.iconColor,
  });

  final MangaUpdateChapter chapter;
  final Color textColor;
  final Color mutedColor;
  final Color brandColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: ShapeBorderClipper(
              shape: MaterialShapeBorder(shape: chapter.shape),
            ),
            child: Image.asset(
              chapter.thumbnailAsset,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: Colors.grey.shade800,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.mangaTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        chapter.chapterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (chapter.pageInfo != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: mutedColor, fontSize: 14),
                      ),
                      Text(
                        chapter.pageInfo!,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.download_for_offline_outlined, color: iconColor),
          ),
        ],
      ),
    );
  }
}
