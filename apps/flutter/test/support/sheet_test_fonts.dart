import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// The package exposes these hooks specifically for deterministic font tests.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;

class _SheetFontManifest implements AssetManifest {
  @override
  List<String> listAssets() => ['Unbounded-Bold.ttf'];

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

Future<void> loadSheetTestFonts() async {
  final bytes = await File(
    'test/fixtures/fonts/Unbounded-Bold.ttf',
  ).readAsBytes();
  GoogleFonts.config.allowRuntimeFetching = false;
  fonts.assetManifest = _SheetFontManifest();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(
          message!.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        return key == 'Unbounded-Bold.ttf' ? ByteData.sublistView(bytes) : null;
      });
  GoogleFonts.unbounded(fontWeight: FontWeight.w700);
  await GoogleFonts.pendingFonts();
}

void clearSheetTestFonts() {
  GoogleFonts.config.allowRuntimeFetching = true;
  fonts.assetManifest = null;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}
