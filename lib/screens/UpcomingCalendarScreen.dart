import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keihatsu/data/mock_updates_feed.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:provider/provider.dart';

class UpcomingCalendarScreen extends StatefulWidget {
  const UpcomingCalendarScreen({super.key});

  @override
  State<UpcomingCalendarScreen> createState() => _UpcomingCalendarScreenState();
}

class _UpcomingCalendarScreenState extends State<UpcomingCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  List<DateTime> _daysInMonthGrid() {
    final DateTime first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final int leading = first.weekday % 7;
    final List<DateTime> days = [];

    for (int i = 0; i < leading; i++) {
      days.add(DateTime(0));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }
    return days;
  }

  List<UpcomingRelease> _releasesFor(DateTime date) {
    final DateTime key = DateTime(date.year, date.month, date.day);
    return mockUpcomingReleases[key] ?? const [];
  }

  int _dotCountFor(DateTime date) {
    final int count = _releasesFor(date).length;
    if (count == 0) return 0;
    return count.clamp(1, 3);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _sectionLabel(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final DateTime todayNormalized =
        DateTime(today.year, today.month, today.day);

    if (_isSameDay(normalized, todayNormalized)) return 'Today';
    if (_isSameDay(
      normalized,
      todayNormalized.add(const Duration(days: 1)),
    )) {
      return 'Tomorrow';
    }
    return DateFormat('EEEE, d MMM').format(normalized);
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
    final List<UpcomingRelease> selectedReleases = _releasesFor(_selectedDate);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: textColor),
                  ),
                  Expanded(
                    child: Text(
                      'Upcoming',
                      style: GoogleFonts.unbounded(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: textColor,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.help_outline_rounded, color: textColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy').format(_visibleMonth),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: textColor),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: Icon(Icons.chevron_right_rounded, color: textColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  _WeekdayLabel('S'),
                  _WeekdayLabel('M'),
                  _WeekdayLabel('T'),
                  _WeekdayLabel('W'),
                  _WeekdayLabel('T'),
                  _WeekdayLabel('F'),
                  _WeekdayLabel('S'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 52,
                ),
                itemCount: _daysInMonthGrid().length,
                itemBuilder: (context, index) {
                  final DateTime day = _daysInMonthGrid()[index];
                  if (day.year == 0) return const SizedBox.shrink();

                  final bool selected = _isSameDay(day, _selectedDate);
                  final int dotCount = _dotCountFor(day);

                  return InkWell(
                    onTap: () => setState(() => _selectedDate = day),
                    borderRadius: BorderRadius.circular(999),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: textColor, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < dotCount; i++) ...[
                                if (i > 0) const SizedBox(width: 2),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: brandColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _sectionLabel(_selectedDate),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (selectedReleases.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: brandColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${selectedReleases.length}',
                        style: TextStyle(
                          color: brandColor.computeLuminance() > 0.55
                              ? const Color(0xFF141410)
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedReleases.isEmpty
                  ? Center(
                      child: Text(
                        'No releases scheduled',
                        style: TextStyle(color: mutedColor, fontSize: 15),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: selectedReleases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final UpcomingRelease release = selectedReleases[index];
                        return Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                release.thumbnailAsset,
                                width: 48,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 68,
                                  color: cs.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                release.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: mutedColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
