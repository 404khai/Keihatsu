import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/CustomBackButton.dart';
import '../components/OfflineImage.dart';
import '../models/local_models.dart';
import '../providers/library_updates_provider.dart';
import '../theme_provider.dart';

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
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  List<DateTime?> _daysInMonthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leading = first.weekday % 7;
    return [
      ...List<DateTime?>.filled(leading, null),
      for (
        var day = 1;
        day <=
            DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
        day++
      )
        DateTime(_visibleMonth.year, _visibleMonth.month, day),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _sectionLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, today.add(const Duration(days: 1)))) return 'Tomorrow';
    return DateFormat('EEEE, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final updates = context.watch<LibraryUpdatesProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final backgroundColor =
        themeProvider.pureBlackDarkMode && themeProvider.isDarkTheme
        ? Colors.black
        : cs.surface;
    final selectedReleases = updates.scheduledEntriesFor(_selectedDate);
    final days = _daysInMonthGrid();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  Expanded(
                    child: Text(
                      'Upcoming',
                      style: GoogleFonts.unbounded(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: cs.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'About release predictions',
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Release predictions'),
                        content: const Text(
                          'Upcoming dates are estimated from each title’s recent upload weekday. Source schedules may change.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                    icon: Icon(Icons.help_outline_rounded, color: cs.onSurface),
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
                        color: cs.onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    _WeekdayLabel(label),
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
                  mainAxisExtent: 54,
                ),
                itemCount: days.length,
                itemBuilder: (_, index) {
                  final day = days[index];
                  if (day == null) return const SizedBox.shrink();
                  final selected = _isSameDay(day, _selectedDate);
                  final count = updates
                      .scheduledEntriesFor(day)
                      .length
                      .clamp(0, 3);
                  final isPast = day.isBefore(
                    DateUtils.dateOnly(DateTime.now()),
                  );
                  return InkWell(
                    onTap: () => setState(() => _selectedDate = day),
                    borderRadius: BorderRadius.circular(999),
                    child: Opacity(
                      opacity: isPast ? 0.38 : 1,
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
                                  ? Border.all(color: cs.onSurface, width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < count; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: themeProvider.brandColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (selectedReleases.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: themeProvider.brandColor,
                      foregroundColor: cs.onPrimary,
                      child: Text(
                        '${selectedReleases.length}',
                        style: const TextStyle(
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
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: selectedReleases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) =>
                          _ReleaseRow(entry: selectedReleases[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseRow extends StatelessWidget {
  const _ReleaseRow({required this.entry});

  final LocalLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OfflineImage(
          imageUrl: entry.thumbnailUrl,
          width: 52,
          height: 72,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            entry.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
