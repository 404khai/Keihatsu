import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/source_rollout.dart';

void main() {
  test(
    'rolls out verified sources while BatCave and WeebCentral stay gated',
    () {
      for (final source in ['manhuatop', 'atsumaru', 'mangafire']) {
        expect(SourceRollout.isAvailable(source), isTrue);
      }
      expect(SourceRollout.isAvailable('MangaFire'), isTrue);
      for (final source in ['weebcentral', 'batcave', 'unknown']) {
        expect(SourceRollout.isAvailable(source), isFalse);
      }
    },
  );
}
