/// Sources cleared for opt-in after the shared source conformance suite passes.
class SourceRollout {
  static const availableIds = {'manhuatop', 'atsumaru', 'mangafire'};

  static bool isAvailable(String sourceId) =>
      availableIds.contains(sourceId.toLowerCase());
}
