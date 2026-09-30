import 'package:intl/intl.dart';

import 'local_models.dart';
import 'user.dart';

class ReadingActivity {
  final String label;
  final double minutes;
  const ReadingActivity(this.label, this.minutes);
}

class ReadingStatistics {
  final List<ReadingActivity> activity;
  final Map<String, double> genres;
  final int chaptersRead;
  final int titlesOpened;
  final int activeDays;
  final double readingMinutes;

  ReadingStatistics._(
    this.activity,
    this.genres,
    this.chaptersRead,
    this.titlesOpened,
    this.activeDays,
    this.readingMinutes,
  );

  factory ReadingStatistics.calculate({
    required List<LocalChapter> chapters,
    required List<LocalManga> mangas,
    required String period,
    UserStats? account,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final today = DateTime.utc(current.year, current.month, current.day);
    final days = switch (period) {
      'Last Month' => 30,
      'Last Year' => 365,
      _ => 7,
    };
    final start = period == 'All Time'
        ? null
        : today.subtract(Duration(days: days - 1));
    bool inPeriod(DateTime date) =>
        !date.isAfter(current) && (start == null || !date.isBefore(start));
    final history = chapters
        .where((c) => c.lastReadAt != null && inPeriod(c.lastReadAt!.toUtc()))
        .toList();
    final completed = history.where((c) => c.isRead).toList();
    String key(String source, String manga) => '$source::$manga';
    final metadata = {for (final m in mangas) key(m.sourceId, m.mangaId): m};
    final counts = <String, int>{};
    for (final c in completed) {
      final names = (metadata[key(c.sourceId, c.mangaId)]?.genres ?? [])
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toSet();
      for (final name in names.isEmpty ? {'Unknown'} : names) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final order = b.value.compareTo(a.value);
        return order == 0 ? a.key.compareTo(b.key) : order;
      });
    final daily = <DateTime, double>{};
    for (final e
        in (account?.dailyReadingTimeMinutes ?? <String, double>{}).entries) {
      final date = DateTime.tryParse('${e.key}T00:00:00Z');
      if (date != null && inPeriod(date) && e.value.isFinite && e.value > 0) {
        daily[date] = e.value;
      }
    }
    final active = history.map((c) {
      final date = c.lastReadAt!.toUtc();
      return DateTime.utc(date.year, date.month, date.day);
    }).toSet()..addAll(daily.keys);
    final activity = <ReadingActivity>[];
    if (period == 'Last Week' || period == 'Last Month') {
      for (var i = days - 1; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        activity.add(
          ReadingActivity(
            DateFormat(period == 'Last Week' ? 'EEE' : 'd MMM').format(date),
            daily[date] ?? 0,
          ),
        );
      }
    } else {
      final months = <DateTime, double>{};
      for (final e in daily.entries) {
        final month = DateTime.utc(e.key.year, e.key.month);
        months[month] = (months[month] ?? 0) + e.value;
      }
      var first = DateTime.utc(
        start?.year ?? today.year - 1,
        start?.month ?? today.month + 1,
      );
      if (period == 'All Time' && months.isNotEmpty) {
        first = months.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      }
      for (
        var month = first;
        !month.isAfter(today);
        month = DateTime.utc(month.year, month.month + 1)
      ) {
        activity.add(
          ReadingActivity(
            DateFormat('MMM yy').format(month),
            months[month] ?? 0,
          ),
        );
      }
    }
    return ReadingStatistics._(
      activity,
      {for (final e in sorted) e.key: e.value / total},
      completed.length,
      history.map((c) => key(c.sourceId, c.mangaId)).toSet().length,
      active.length,
      daily.values.fold(0.0, (a, b) => a + b),
    );
  }
}
