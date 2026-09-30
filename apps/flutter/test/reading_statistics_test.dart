import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:keihatsu/models/reading_statistics.dart';
import 'package:keihatsu/models/user.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12);
  UserStats account() => UserStats.fromJson({
    'dailyReadingTimeMinutes': {
      '2026-09-24': 20,
      '2026-09-25': 30.5,
      '2026-10-01': 60,
      '2026-10-02': 99,
    },
  });
  test('rolling periods include boundary and exclude future data', () {
    final week = ReadingStatistics.calculate(
      chapters: [],
      mangas: [],
      period: 'Last Week',
      account: account(),
      now: now,
    );
    expect(week.activity.length, 7);
    expect(week.readingMinutes, 90.5);
    expect(week.activity.first.minutes, 30.5);
    expect(week.activity.last.minutes, 60);
    final month = ReadingStatistics.calculate(
      chapters: [],
      mangas: [],
      period: 'Last Month',
      account: account(),
      now: now,
    );
    expect(month.readingMinutes, 110.5);
    expect(month.activity.length, 30);
  });
  test('counts completed chapters and distinct source/title identities', () {
    LocalChapter chapter(String source, String id, bool read) => LocalChapter()
      ..sourceId = source
      ..mangaId = 'same'
      ..chapterId = id
      ..isRead = read
      ..lastReadAt = now;
    final manga = LocalManga()
      ..sourceId = 'a'
      ..mangaId = 'same'
      ..genres = ['Action', 'Action', 'Fantasy'];
    final stats = ReadingStatistics.calculate(
      chapters: [
        chapter('a', '1', true),
        chapter('a', '2', true),
        chapter('b', '1', true),
        chapter('a', '3', false),
      ],
      mangas: [manga],
      period: 'All Time',
      now: now,
    );
    expect(stats.chaptersRead, 3);
    expect(stats.titlesOpened, 2);
    expect(stats.genres, {'Action': 0.4, 'Fantasy': 0.4, 'Unknown': 0.2});
  });
  test('old account payload and empty history have zero stats', () {
    final account = UserStats.fromJson({'totalReadingTimeMinutes': 42});
    expect(account.dailyReadingTimeMinutes, isEmpty);
    final stats = ReadingStatistics.calculate(
      chapters: [],
      mangas: [],
      period: 'Last Week',
      account: account,
      now: now,
    );
    expect(stats.readingMinutes, 0);
    expect(stats.genres, isEmpty);
    expect(stats.activeDays, 0);
  });
}
