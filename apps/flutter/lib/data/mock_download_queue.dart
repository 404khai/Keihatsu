import 'package:keihatsu/models/local_models.dart';

/// Extension source IDs mapped to local icon assets.
const Map<String, String> extensionImages = {
  'mangafire': 'images/extensions/mangafire.png',
  'weebcentral': 'images/extensions/weebcentral.png',
  'batcave': 'images/extensions/batcave.png',
  'atsumaru': 'images/extensions/atsumaru.png',
  'manhuatop': 'images/extensions/manhuatop.jpeg',
};

/// Mock download queue grouped by real extensions — manwha covers without "2".
final List<DownloadQueueItem> mockDownloadQueue = [
  // MangaFire — Latna Saga (3 chapters)
  _item(
    chapterId: 'mock-mf-1',
    mangaId: 'latnasaga',
    mangaTitle: 'Latna Saga',
    chapterName: 'Chapter 47',
    chapterNumber: 47,
    thumbnail: 'images/manwha/latnasaga.png',
    extensionName: 'MangaFire',
    sourceId: 'mangafire',
    status: 1,
    progress: 0.6,
    priority: 0,
  ),
  _item(
    chapterId: 'mock-mf-2',
    mangaId: 'latnasaga',
    mangaTitle: 'Latna Saga',
    chapterName: 'Chapter 48',
    chapterNumber: 48,
    thumbnail: 'images/manwha/latnasaga.png',
    extensionName: 'MangaFire',
    sourceId: 'mangafire',
    status: 0,
    priority: 1,
  ),
  _item(
    chapterId: 'mock-mf-3',
    mangaId: 'latnasaga',
    mangaTitle: 'Latna Saga',
    chapterName: 'Chapter 49',
    chapterNumber: 49,
    thumbnail: 'images/manwha/latnasaga.png',
    extensionName: 'MangaFire',
    sourceId: 'mangafire',
    status: 0,
    priority: 2,
  ),
  _item(
    chapterId: 'mock-mf-4',
    mangaId: 'disasterclass',
    mangaTitle: 'Disaster Class Hero',
    chapterName: 'Chapter 72',
    chapterNumber: 72,
    thumbnail: 'images/manwha/disasterclass.png',
    extensionName: 'MangaFire',
    sourceId: 'mangafire',
    status: 0,
    priority: 3,
  ),

  // WeebCentral — Northern Blade + Ordeal (2 chapters)
  _item(
    chapterId: 'mock-wc-1',
    mangaId: 'northernblade',
    mangaTitle: 'Northern Blade',
    chapterName: 'Chapter 182',
    chapterNumber: 182,
    thumbnail: 'images/manwha/northernblade.png',
    extensionName: 'WeebCentral',
    sourceId: 'weebcentral',
    status: 1,
    progress: 0.35,
    priority: 4,
  ),
  _item(
    chapterId: 'mock-wc-2',
    mangaId: 'ordeal',
    mangaTitle: 'Ordeal',
    chapterName: 'Chapter 91',
    chapterNumber: 91,
    thumbnail: 'images/manwha/ordeal.png',
    extensionName: 'WeebCentral',
    sourceId: 'weebcentral',
    status: 0,
    priority: 5,
  ),
  _item(
    chapterId: 'mock-wc-3',
    mangaId: 'ordeal',
    mangaTitle: 'Ordeal',
    chapterName: 'Chapter 92',
    chapterNumber: 92,
    thumbnail: 'images/manwha/ordeal.png',
    extensionName: 'WeebCentral',
    sourceId: 'weebcentral',
    status: 0,
    priority: 6,
  ),

  // BatCave — Swords Master (3 chapters)
  _item(
    chapterId: 'mock-bc-1',
    mangaId: 'sssranker',
    mangaTitle: 'SSS Ranker',
    chapterName: 'Chapter 33',
    chapterNumber: 33,
    thumbnail: 'images/manwha/sssranker.png',
    extensionName: 'BatCave',
    sourceId: 'batcave',
    status: 0,
    priority: 7,
  ),
  _item(
    chapterId: 'mock-bc-2',
    mangaId: 'swordsmaster',
    mangaTitle: 'Swords Master',
    chapterName: 'Chapter 58',
    chapterNumber: 58,
    thumbnail: 'images/manwha/swordsmaster.png',
    extensionName: 'BatCave',
    sourceId: 'batcave',
    status: 0,
    priority: 8,
  ),
  _item(
    chapterId: 'mock-bc-3',
    mangaId: 'swordsmaster',
    mangaTitle: 'Swords Master',
    chapterName: 'Chapter 59',
    chapterNumber: 59,
    thumbnail: 'images/manwha/swordsmaster.png',
    extensionName: 'BatCave',
    sourceId: 'batcave',
    status: 0,
    priority: 9,
  ),
  _item(
    chapterId: 'mock-bc-4',
    mangaId: 'swordsmaster',
    mangaTitle: 'Swords Master',
    chapterName: 'Chapter 60',
    chapterNumber: 60,
    thumbnail: 'images/manwha/swordsmaster.png',
    extensionName: 'BatCave',
    sourceId: 'batcave',
    status: 0,
    priority: 10,
  ),

  // Atsumaru
  _item(
    chapterId: 'mock-at-1',
    mangaId: 'pickmeup',
    mangaTitle: 'Pick Me Up',
    chapterName: 'Chapter 66',
    chapterNumber: 66,
    thumbnail: 'images/manwha/pickmeup.png',
    extensionName: 'Atsumaru',
    sourceId: 'atsumaru',
    status: 0,
    priority: 11,
  ),
  _item(
    chapterId: 'mock-at-2',
    mangaId: 'maxlvlnewbie',
    mangaTitle: 'Max Level Newbie',
    chapterName: 'Chapter 104',
    chapterNumber: 104,
    thumbnail: 'images/manwha/maxlvlnewbie.png',
    extensionName: 'Atsumaru',
    sourceId: 'atsumaru',
    status: 0,
    priority: 12,
  ),

  // ManhuaTop — Dungeon Raid (2 chapters)
  _item(
    chapterId: 'mock-mt-1',
    mangaId: 'dugeonraid',
    mangaTitle: 'Dungeon Raid',
    chapterName: 'Chapter 19',
    chapterNumber: 19,
    thumbnail: 'images/manwha/dugeonraid.png',
    extensionName: 'ManhuaTop',
    sourceId: 'manhuatop',
    status: 0,
    priority: 13,
  ),
  _item(
    chapterId: 'mock-mt-2',
    mangaId: 'dugeonraid',
    mangaTitle: 'Dungeon Raid',
    chapterName: 'Chapter 20',
    chapterNumber: 20,
    thumbnail: 'images/manwha/dugeonraid.png',
    extensionName: 'ManhuaTop',
    sourceId: 'manhuatop',
    status: 0,
    priority: 14,
  ),
  _item(
    chapterId: 'mock-mt-3',
    mangaId: 'superhumanbattlefield',
    mangaTitle: 'Superhuman Battlefield',
    chapterName: 'Chapter 28',
    chapterNumber: 28,
    thumbnail: 'images/manwha/superhumanbattlefield.png',
    extensionName: 'ManhuaTop',
    sourceId: 'manhuatop',
    status: 0,
    priority: 15,
  ),
];

DownloadQueueItem _item({
  required String chapterId,
  required String mangaId,
  required String mangaTitle,
  required String chapterName,
  required double chapterNumber,
  required String thumbnail,
  required String extensionName,
  required String sourceId,
  int status = 0,
  double progress = 0,
  int priority = 0,
}) {
  final item = DownloadQueueItem()
    ..chapterId = chapterId
    ..mangaId = mangaId
    ..sourceId = sourceId
    ..chapterName = chapterName
    ..chapterNumber = chapterNumber
    ..mangaTitle = mangaTitle
    ..mangaThumbnail = thumbnail
    ..extensionName = extensionName
    ..status = status
    ..progress = progress
    ..priority = priority;
  return item;
}

String? extensionImageFor(String sourceId) =>
    extensionImages[sourceId.toLowerCase()];
