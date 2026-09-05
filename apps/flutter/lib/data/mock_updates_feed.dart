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
        thumbnailAsset: 'images/manwha/pickmeup.png',
        chapterLabel: 'Chapter 208',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Pick Me Up',
        thumbnailAsset: 'images/manwha/pickmeup.png',
        chapterLabel: 'Chapter 207',
        pageInfo: 'Page: 2',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Pick Me Up',
        thumbnailAsset: 'images/manwha/pickmeup.png',
        chapterLabel: 'Chapter 206',
        shape: _shapeAt(0),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.png',
        chapterLabel: 'Chapter 64',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.png',
        chapterLabel: 'Chapter 62',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.png',
        chapterLabel: 'Chapter 61',
        shape: _shapeAt(1),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Death God',
        thumbnailAsset: 'images/manwha/blacksun.png',
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
        thumbnailAsset: 'images/manwha/ordeal.png',
        chapterLabel: 'Chapter 132',
        shape: _shapeAt(2),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Northern Blade',
        thumbnailAsset: 'images/manwha/northernblade.png',
        chapterLabel: 'Chapter 98',
        shape: _shapeAt(3),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Latna Saga',
        thumbnailAsset: 'images/manwha/latnasaga.png',
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
        thumbnailAsset: 'images/manwha/sssranker.png',
        chapterLabel: 'Chapter 52',
        shape: _shapeAt(5),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Max Level Newbie',
        thumbnailAsset: 'images/manwha/maxlvlnewbie.png',
        chapterLabel: 'Chapter 26',
        shape: _shapeAt(6),
      ),
      MangaUpdateChapter(
        mangaTitle: 'Superhuman Battlefield',
        thumbnailAsset: 'images/manwha/superhumanbattlefield.png',
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
      thumbnailAsset: 'images/manwha/twatf.png',
      shape: _shapeAt(0),
    ),
    UpcomingRelease(
      title: 'My bias gets on the last train',
      thumbnailAsset: 'images/manwha/player2.png',
      shape: _shapeAt(1),
    ),
    UpcomingRelease(
      title: "The Regressed Mercenary's Machinations",
      thumbnailAsset: 'images/manwha/mercenary.png',
      shape: _shapeAt(2),
    ),
    UpcomingRelease(
      title: 'Dungeon Raid',
      thumbnailAsset: 'images/manwha/dugeonraid.png',
      shape: _shapeAt(3),
    ),
  ],
  DateTime(2026, 7, 16): [
    UpcomingRelease(
      title: 'SSS Ranker',
      thumbnailAsset: 'images/manwha/sssranker.png',
      shape: _shapeAt(4),
    ),
    UpcomingRelease(
      title: 'Max Level Newbie',
      thumbnailAsset: 'images/manwha/maxlvlnewbie.png',
      shape: _shapeAt(5),
    ),
  ],
  DateTime(2026, 7, 17): [
    UpcomingRelease(
      title: 'Ordeal',
      thumbnailAsset: 'images/manwha/ordeal.png',
      shape: _shapeAt(6),
    ),
    UpcomingRelease(
      title: 'Northern Blade',
      thumbnailAsset: 'images/manwha/northernblade.png',
      shape: _shapeAt(7),
    ),
  ],
  DateTime(2026, 7, 18): [
    UpcomingRelease(
      title: 'Pick Me Up',
      thumbnailAsset: 'images/manwha/pickmeup.png',
      shape: _shapeAt(0),
    ),
    UpcomingRelease(
      title: 'Latna Saga',
      thumbnailAsset: 'images/manwha/latnasaga.png',
      shape: _shapeAt(1),
    ),
  ],
  DateTime(2026, 7, 19): [
    UpcomingRelease(
      title: 'Superhuman Battlefield',
      thumbnailAsset: 'images/manwha/superhumanbattlefield.png',
      shape: _shapeAt(2),
    ),
    UpcomingRelease(
      title: 'Disaster Class Hero',
      thumbnailAsset: 'images/manwha/disasterclass.png',
      shape: _shapeAt(3),
    ),
  ],
  DateTime(2026, 7, 20): [
    UpcomingRelease(
      title: 'Adventurer',
      thumbnailAsset: 'images/manwha/adventurer.png',
      shape: _shapeAt(4),
    ),
    UpcomingRelease(
      title: 'Sword Master',
      thumbnailAsset: 'images/manwha/swordsmaster.png',
      shape: _shapeAt(5),
    ),
  ],
  DateTime(2026, 7, 22): [
    UpcomingRelease(
      title: 'Mafia Nanny',
      thumbnailAsset: 'images/manwha/mafiananny.png',
      shape: _shapeAt(6),
    ),
  ],
  DateTime(2026, 7, 29): [
    UpcomingRelease(
      title: 'Black Sun',
      thumbnailAsset: 'images/manwha/blacksun.png',
      shape: _shapeAt(7),
    ),
  ],
};
