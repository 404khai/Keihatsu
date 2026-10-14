import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/ota_diagnostics.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class LocalUpdater extends Fake implements ShorebirdUpdater {
  LocalUpdater({
    this.available = true,
    this.patch,
    this.fail = false,
    this.hang = false,
  });

  final bool available;
  final Patch? patch;
  final bool fail;
  final bool hang;
  int reads = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<Patch?> readCurrentPatch() async {
    reads++;
    if (fail) throw StateError('Updater unavailable');
    if (hang) return Completer<Patch?>().future;
    return patch;
  }

  // Fake rejects unexpected method calls, including all network operations.
}

void main() {
  test('ordinary Flutter builds skip patch reads and network calls', () async {
    final updater = LocalUpdater(available: false);
    final info = await OtaBootInfo.read(updater);
    expect(info.available, isFalse);
    expect(info.patchNumber, isNull);
    expect(updater.reads, 0);
  });

  test('distinguishes the baseline from the currently booted patch', () async {
    expect((await OtaBootInfo.read(LocalUpdater())).patchNumber, 0);
    expect(
      (await OtaBootInfo.read(
        LocalUpdater(patch: const Patch(number: 3)),
      )).patchNumber,
      3,
    );
  });

  test('updater failures do not escape into startup', () async {
    final info = await OtaBootInfo.read(LocalUpdater(fail: true));
    expect(info.available, isTrue);
    expect(info.patchNumber, isNull);
  });

  testWidgets('a stalled local read times out without checking the network', (
    tester,
  ) async {
    final pending = OtaBootInfo.read(LocalUpdater(hang: true));
    await tester.pump(const Duration(seconds: 3));
    final info = await pending;
    expect(info.available, isTrue);
    expect(info.patchNumber, isNull);
  });
}
