import 'package:keihatsu/common/shape_values.dart';
import 'package:material_shapes/material_shapes.dart';

class MangaUpdateChapter {
  const MangaUpdateChapter({
    required this.mangaTitle,
    required this.thumbnailAsset,
    required this.chapterLabel,
    required this.shape,
    this.pageInfo,
  });

  final String mangaTitle;
  final String thumbnailAsset;
  final String chapterLabel;
  final String? pageInfo;
  final RoundedPolygon shape;
}

class UpdatesDayGroup {
  const UpdatesDayGroup({
    required this.date,
    required this.chapters,
  });

  final DateTime date;
  final List<MangaUpdateChapter> chapters;
}

RoundedPolygon _shapeAt(int index) =>
    ShapeValues.updateThumbnails[index % ShapeValues.updateThumbnails.length];

final List<UpdatesDayGroup> mockUpdatesFeed = [
  UpdatesDayGroup(
    date: DateTime(2026, 7, 4),
    chapters: [
      MangaUpdateChapter(
        mangaTitle: 'Pick Me Up',
        thumbnailAsset: 'images/manwha/pickmeup.webp',
        chapterLabel: 'Chapter 208',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Pick Me Up',
        thumbnailAsset: 'images/manwha/pickmeup.webp',
        chapterLabel: 'Chapter 207',
        pageInfo: 'Page: 2',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Pick Me Up',
        thumbnailAsset: 'images/manwha/pickmeup.webp',
        chapterLabel: 'Chapter 206',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.webp',
        chapterLabel: 'Chapter 64',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.webp',
        chapterLabel: 'Chapter 62',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.webp',
        chapterLabel: 'Chapter 61',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.webp',
        chapterLabel: 'Episode 48',
        shape: _shapeAt(1),
      ),
    ],
  ),
  UpdatesDayGroup(
    date: DateTime(2026, 7, 3),
    chapters: [
      MangaUpdateChapter(
        mangaTitle: 'Ordeal',
        thumbnailAsset: 'images/manwha/ordeal.webp',
        chapterLabel: 'Chapter 132',
        shape: _shapeAt(2),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Northern Blade',
        thumbnailAsset: 'images/manwha/northernblade.webp',
        chapterLabel: 'Chapter 98',
        shape: _shapeAt(3),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Latna Saga',
        thumbnailAsset: 'images/manwha/latnasaga.webp',
        chapterLabel: 'Chapter 8',
        shape: _shapeAt(4),
      ),
    ],
  ),
  UpdatesDayGroup(
    date: DateTime(2026, 7, 2),
    chapters: [
      MangaUpdateChapter(
        mangaTitle: 'SSS Ranker',
        thumbnailAsset: 'images/manwha/sssranker.webp',
        chapterLabel: 'Chapter 52',
        shape: _shapeAt(5),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Max Level Newbie',
        thumbnailAsset: 'images/manwha/maxlvlnewbie.webp',
        chapterLabel: 'Chapter 26',
        shape: _shapeAt(6),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Superhuman Battlefield',
        thumbnailAsset: 'images/manwha/superhumanbattlefield.webp',
        chapterLabel: 'Chapter 34',
        shape: _shapeAt(7),
      ),
    ],
  ),
];

class UpcomingRelease {
  const UpcomingRelease({
    required this.title,
    required this.thumbnailAsset,
    required this.shape,
  });

  final String title;
  final String thumbnailAsset;
  final RoundedPolygon shape;
}

/// Dates with scheduled releases — dot count matches list length (capped at 3).
final Map<DateTime, List<UpcomingRelease>> mockUpcomingReleases = {
  DateTime(2026, 7, 15): [
    UpcomingRelease(
      title: 'Tears on a Withered Flower',
      thumbnailAsset: 'images/manwha/twatf.webp',
      shape: _shapeAt(0),
    ),
    UpcomingRelease(
      title: 'My bias gets on the last train',
      thumbnailAsset: 'images/manwha/player2.webp',
      shape: _shapeAt(1),
    ),
    UpcomingRelease(
      title: "The Regressed Mercenary's Machinations",
      thumbnailAsset: 'images/manwha/mercenary.webp',
      shape: _shapeAt(2),
    ),
    UpcomingRelease(
      title: 'Dungeon Raid',
      thumbnailAsset: 'images/manwha/dugeonraid.webp',
      shape: _shapeAt(3),
    ),
  ],
  DateTime(2026, 7, 16): [
    UpcomingRelease(
      title: 'SSS Ranker',
      thumbnailAsset: 'images/manwha/sssranker.webp',
      shape: _shapeAt(4),
    ),
    UpcomingRelease(
      title: 'Max Level Newbie',
      thumbnailAsset: 'images/manwha/maxlvlnewbie.webp',
      shape: _shapeAt(5),
    ),
  ],
  DateTime(2026, 7, 17): [
    UpcomingRelease(
      title: 'Ordeal',
      thumbnailAsset: 'images/manwha/ordeal.webp',
      shape: _shapeAt(6),
    ),
    UpcomingRelease(
      title: 'Northern Blade',
      thumbnailAsset: 'images/manwha/northernblade.webp',
      shape: _shapeAt(7),
    ),
  ],
  DateTime(2026, 7, 18): [
    UpcomingRelease(
      title: 'Pick Me Up',
      thumbnailAsset: 'images/manwha/pickmeup.webp',
      shape: _shapeAt(0),
    ),
    UpcomingRelease(
      title: 'Latna Saga',
      thumbnailAsset: 'images/manwha/latnasaga.webp',
      shape: _shapeAt(1),
    ),
  ],
  DateTime(2026, 7, 19): [
    UpcomingRelease(
      title: 'Superhuman Battlefield',
      thumbnailAsset: 'images/manwha/superhumanbattlefield.webp',
      shape: _shapeAt(2),
    ),
    UpcomingRelease(
      title: 'Disaster Class Hero',
      thumbnailAsset: 'images/manwha/disasterclass.webp',
      shape: _shapeAt(3),
    ),
  ],
  DateTime(2026, 7, 20): [
    UpcomingRelease(
      title: 'Adventurer',
      thumbnailAsset: 'images/manwha/adventurer.webp',
      shape: _shapeAt(4),
    ),
    UpcomingRelease(
      title: 'Sword Master',
      thumbnailAsset: 'images/manwha/swordsmaster.webp',
      shape: _shapeAt(5),
    ),
  ],
  DateTime(2026, 7, 22): [
    UpcomingRelease(
      title: 'Mafia Nanny',
      thumbnailAsset: 'images/manwha/mafiananny.webp',
      shape: _shapeAt(6),
    ),
  ],
  DateTime(2026, 7, 29): [
    UpcomingRelease(
      title: 'Black Sun',
      thumbnailAsset: 'images/manwha/blacksun.webp',
      shape: _shapeAt(7),
    ),
  ],
};
