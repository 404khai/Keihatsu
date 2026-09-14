import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum KeihatsuSeason {
  spring,
  summer,
  autumn,
  winter;

  factory KeihatsuSeason.fromDate(DateTime date) {
    return switch (date.month) {
      >= 3 && <= 5 => KeihatsuSeason.spring,
      >= 6 && <= 8 => KeihatsuSeason.summer,
      >= 9 && <= 11 => KeihatsuSeason.autumn,
      _ => KeihatsuSeason.winter,
    };
  }

  String get iconAsset =>
      'images/icons/appIcons/${switch (this) {
        KeihatsuSeason.spring => 'KeihatsuSpringIcon.png',
        KeihatsuSeason.summer => 'KeihatsuIcon.png',
        KeihatsuSeason.autumn => 'KeihatsuAutumnIcon.png',
        KeihatsuSeason.winter => 'KeihatsuWinterIcon.png',
      }}';

  String? get alternateIconName => switch (this) {
    KeihatsuSeason.spring => 'KeihatsuSpringIcon',
    KeihatsuSeason.summer => null,
    KeihatsuSeason.autumn => 'KeihatsuAutumnIcon',
    KeihatsuSeason.winter => 'KeihatsuWinterIcon',
  };
}

abstract final class SeasonalBranding {
  static KeihatsuSeason current({DateTime? at}) {
    return KeihatsuSeason.fromDate(at ?? DateTime.now());
  }
}

abstract final class SeasonalAppIconService {
  static const MethodChannel _channel = MethodChannel(
    'keihatsu/seasonal_branding',
  );

  static Future<void> syncIcon({DateTime? at}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSeason', {
        'season': SeasonalBranding.current(at: at).name,
      });
    } on PlatformException catch (error) {
      debugPrint('Unable to update the seasonal app icon: ${error.message}');
    } on MissingPluginException {
      debugPrint('Seasonal app icon bridge is unavailable.');
    }
  }
}

class SeasonalBrandingLifecycle extends StatefulWidget {
  const SeasonalBrandingLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<SeasonalBrandingLifecycle> createState() =>
      _SeasonalBrandingLifecycleState();
}

class _SeasonalBrandingLifecycleState extends State<SeasonalBrandingLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeasonalAppIconService.syncIcon();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SeasonalAppIconService.syncIcon();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
