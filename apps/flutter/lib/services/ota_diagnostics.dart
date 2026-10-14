import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Local boot metadata only: this never checks for or downloads updates.
class OtaBootInfo {
  const OtaBootInfo({required this.available, this.patchNumber});

  final bool available;

  /// Zero is the unpatched baseline; null means the read failed.
  final int? patchNumber;

  static Future<OtaBootInfo> read(ShorebirdUpdater updater) async {
    var available = false;
    try {
      available = updater.isAvailable;
      if (!available) {
        return const OtaBootInfo(available: false);
      }
      final patch = await updater.readCurrentPatch().timeout(
        const Duration(seconds: 2),
      );
      return OtaBootInfo(available: true, patchNumber: patch?.number ?? 0);
    } catch (_) {
      // Diagnostic failures must never prevent offline reading or app launch.
      return OtaBootInfo(available: available);
    }
  }
}

Future<void> recordOtaDiagnostics() async {
  try {
    final boot = await OtaBootInfo.read(ShorebirdUpdater());
    final package = await PackageInfo.fromPlatform();
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCustomKey('shorebird_available', boot.available);
    await crashlytics.setCustomKey(
      'shorebird_patch',
      boot.patchNumber ?? 'unavailable',
    );
    await crashlytics.setCustomKey(
      'shorebird_release',
      '${package.version}+${package.buildNumber}',
    );
  } catch (_) {
    // Firebase may be unavailable in local builds. No update UI or startup gate.
  }
}
