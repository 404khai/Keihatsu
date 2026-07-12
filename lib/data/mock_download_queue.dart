import 'package:keihatsu/models/local_models.dart';

/// Mock download queue for preview — uses manwha covers without "2" suffix.
final List<DownloadQueueItem> mockDownloadQueue = [
  _item(
    chapterId: 'mock-1',
    mangaId: 'latnasaga',
    mangaTitle: 'Latna Saga',
    chapterName: 'Chapter 47',
    chapterNumber: 47,
    thumbnail: 'images/manwha/latnasaga.png',
    extensionName: 'Asura Scans',
    status: 1,
    progress: 0.6,
    priority: 0,
  ),
  _item(
    chapterId: 'mock-2',
    mangaId: 'northernblade',
    mangaTitle: 'Northern Blade',
    chapterName: 'Chapter 182',
    chapterNumber: 182,
    thumbnail: 'images/manwha/northernblade.png',
    extensionName: 'Reaper Scans',
    status: 0,
    priority: 1,
  ),
  _item(
    chapterId: 'mock-3',
    mangaId: 'ordeal',
    mangaTitle: 'Ordeal',
    chapterName: 'Chapter 91',
    chapterNumber: 91,
    thumbnail: 'images/manwha/ordeal.png',
    extensionName: 'Asura Scans',
    status: 0,
    priority: 2,
  ),
  _item(
    chapterId: 'mock-4',
    mangaId: 'sssranker',
    mangaTitle: 'SSS Ranker',
    chapterName: 'Chapter 33',
    chapterNumber: 33,
    thumbnail: 'images/manwha/sssranker.png',
    extensionName: 'Flame Scans',
    status: 2,
    priority: 3,
  ),
  _item(
    chapterId: 'mock-5',
    mangaId: 'swordsmaster',
    mangaTitle: 'Swords Master',
    chapterName: 'Chapter 58',
    chapterNumber: 58,
    thumbnail: 'images/manwha/swordsmaster.png',
    extensionName: 'Reaper Scans',
    status: 2,
    priority: 4,
  ),
  _item(
    chapterId: 'mock-6',
    mangaId: 'disasterclass',
    mangaTitle: 'Disaster Class Hero',
    chapterName: 'Chapter 72',
    chapterNumber: 72,
    thumbnail: 'images/manwha/disasterclass.png',
    extensionName: 'Asura Scans',
    status: 2,
    priority: 5,
  ),
  _item(
    chapterId: 'mock-7',
    mangaId: 'dugeonraid',
    mangaTitle: 'Dungeon Raid',
    chapterName: 'Chapter 19',
    chapterNumber: 19,
    thumbnail: 'images/manwha/dugeonraid.png',
    extensionName: 'Flame Scans',
    status: 2,
    priority: 6,
  ),
  _item(
    chapterId: 'mock-8',
    mangaId: 'maxlvlnewbie',
    mangaTitle: 'Max Level Newbie',
    chapterName: 'Chapter 104',
    chapterNumber: 104,
    thumbnail: 'images/manwha/maxlvlnewbie.png',
    extensionName: 'Reaper Scans',
    status: 2,
    priority: 7,
  ),
  _item(
    chapterId: 'mock-9',
    mangaId: 'pickmeup',
    mangaTitle: 'Pick Me Up',
    chapterName: 'Chapter 66',
    chapterNumber: 66,
    thumbnail: 'images/manwha/pickmeup.png',
    extensionName: 'Asura Scans',
    status: 2,
    priority: 8,
  ),
  _item(
    chapterId: 'mock-10',
    mangaId: 'superhumanbattlefield',
    mangaTitle: 'Superhuman Battlefield',
    chapterName: 'Chapter 28',
    chapterNumber: 28,
    thumbnail: 'images/manwha/superhumanbattlefield.png',
    extensionName: 'Flame Scans',
    status: 2,
    priority: 9,
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
  int status = 0,
  double progress = 0,
  int priority = 0,
}) {
  final item = DownloadQueueItem()
    ..chapterId = chapterId
    ..mangaId = mangaId
    ..sourceId = 'mock-source'
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
