import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/seasonal_branding_service.dart';

void main() {
  test('resolves every Keihatsu branding season boundary', () {
    final expected = <int, KeihatsuSeason>{
      1: KeihatsuSeason.winter,
      2: KeihatsuSeason.winter,
      3: KeihatsuSeason.spring,
      5: KeihatsuSeason.spring,
      6: KeihatsuSeason.summer,
      8: KeihatsuSeason.summer,
      9: KeihatsuSeason.autumn,
      11: KeihatsuSeason.autumn,
      12: KeihatsuSeason.winter,
    };

    for (final entry in expected.entries) {
      expect(
        KeihatsuSeason.fromDate(DateTime(2026, entry.key, 1)),
        entry.value,
      );
    }
  });

  test('maps summer to primary and alternates to their exact icon names', () {
    expect(KeihatsuSeason.spring.alternateIconName, 'KeihatsuSpringIcon');
    expect(KeihatsuSeason.summer.alternateIconName, isNull);
    expect(KeihatsuSeason.autumn.alternateIconName, 'KeihatsuAutumnIcon');
    expect(KeihatsuSeason.winter.alternateIconName, 'KeihatsuWinterIcon');
  });

  test('exposes exact seasonal artwork paths', () {
    expect(
      KeihatsuSeason.summer.iconAsset,
      'images/icons/appIcons/KeihatsuIcon.png',
    );
    expect(
      KeihatsuSeason.spring.iconAsset,
      'images/icons/appIcons/KeihatsuSpringIcon.png',
    );
    expect(
      KeihatsuSeason.autumn.iconAsset,
      'images/icons/appIcons/KeihatsuAutumnIcon.png',
    );
    expect(
      KeihatsuSeason.winter.iconAsset,
      'images/icons/appIcons/KeihatsuWinterIcon.png',
    );
  });
}
