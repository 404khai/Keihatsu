import 'package:flutter_test/flutter_test.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class FakeAppUpdater extends Fake implements ShorebirdUpdater {
  bool available = true;
  Patch? current;
  Patch? next;
  UpdateStatus status = UpdateStatus.upToDate;
  int checks = 0;
  int downloads = 0;
  bool readFails = false;
  Future<UpdateStatus> Function()? onCheck;
  Future<void> Function()? onDownload;

  @override
  bool get isAvailable => available;

  @override
  Future<Patch?> readCurrentPatch() async {
    if (readFails) throw StateError('local read failed');
    return current;
  }

  @override
  Future<Patch?> readNextPatch() async => next;

  @override
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    checks++;
    return onCheck == null ? status : await onCheck!();
  }

  @override
  Future<void> update({UpdateTrack? track}) async {
    downloads++;
    await onDownload?.call();
  }
}
