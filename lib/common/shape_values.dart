import 'package:material_shapes/material_shapes.dart';

/// BunPod cover clip shapes for manga thumbnails.
abstract final class ShapeValues {
  static final cover = MaterialShapes.clover4Leaf;
  static final coverFocused = MaterialShapes.cookie7Sided;

  /// Rotating M3E shapes for compact update list thumbnails.
  static final updateThumbnails = [
    MaterialShapes.softBurst,
    MaterialShapes.clover4Leaf,
    MaterialShapes.gem,
    MaterialShapes.slanted,
    MaterialShapes.cookie7Sided,
    MaterialShapes.arch,
    MaterialShapes.sunny,
    MaterialShapes.pentagon,
  ];
}
