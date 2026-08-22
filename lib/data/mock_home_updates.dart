import 'package:keihatsu/common/shape_values.dart';
import 'package:material_shapes/material_shapes.dart';

class HomeUpdateEntry {
  const HomeUpdateEntry({
    required this.title,
    required this.chapters,
    required this.thumbnailAsset,
    required this.shape,
    this.scheduled = false,
  });

  final String title;
  final String chapters;
  final String thumbnailAsset;
  final RoundedPolygon shape;
  final bool scheduled;
}

class HomeUpdateGroup {
  const HomeUpdateGroup({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<HomeUpdateEntry> entries;
}

RoundedPolygon _shapeAt(int index) =>
    ShapeValues.updateThumbnails[index % ShapeValues.updateThumbnails.length];

/// Grouped home updates — mirrors the M3E Updates screen layout.
final List<HomeUpdateGroup> mockHomeUpdates = [
  HomeUpdateGroup(
    label: 'Today',
    entries: [
      HomeUpdateEntry(
        title: 'Ordeal',
        chapters: 'Chapter 132, 135...',
        thumbnailAsset: 'images/manwha/ordeal.png',
        shape: _shapeAt(0),
      ),
      HomeUpdateEntry(
        title: 'Northern Blade',
        chapters: 'Chapter 98, 104...',
        thumbnailAsset: 'images/manwha/northernblade.png',
        shape: _shapeAt(1),
      ),
      HomeUpdateEntry(
        title: 'Latna Saga',
        chapters: 'Chapter 8',
        thumbnailAsset: 'images/manwha/latnasaga.png',
        shape: _shapeAt(2),
      ),
      HomeUpdateEntry(
        title: 'Pick Me Up',
        chapters: 'Chapter 89, 90...',
        thumbnailAsset: 'images/manwha/pickmeup.png',
        shape: _shapeAt(3),
      ),
    ],
  ),
  HomeUpdateGroup(
    label: 'Tomorrow',
    entries: [
      HomeUpdateEntry(
        title: 'SSS Ranker',
        chapters: 'Chapter 52, 53...',
        thumbnailAsset: 'images/manwha/sssranker.png',
        shape: _shapeAt(4),
        scheduled: true,
      ),
      HomeUpdateEntry(
        title: 'Max Level Newbie',
        chapters: 'Chapter 26, 27...',
        thumbnailAsset: 'images/manwha/maxlvlnewbie.png',
        shape: _shapeAt(5),
        scheduled: true,
      ),
      HomeUpdateEntry(
        title: 'Superhuman Battlefield',
        chapters: 'Chapter 34, 35...',
        thumbnailAsset: 'images/manwha/superhumanbattlefield.png',
        shape: _shapeAt(6),
        scheduled: true,
      ),
    ],
  ),
];
