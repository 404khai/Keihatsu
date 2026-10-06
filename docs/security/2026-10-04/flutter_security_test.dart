// Run from apps/flutter: flutter test ../../docs/security/2026-10-04/flutter_security_test.dart
// These probes assert the CURRENT vulnerable behavior, not the desired behavior.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/file_service.dart';
import 'package:keihatsu/services/api_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class TestPaths extends PathProviderPlatform {
  TestPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SEC-01: default authentication endpoint uses HTTP', () {
    expect(Uri.parse(ApiConstants.baseUrl).scheme, 'http');
  });
  test('SEC-03: crafted chapter IDs delete a directory outside documents', () async {
    final sandbox = await Directory.systemTemp.createTemp('keihatsu-security-');
    final docs = Directory(p.join(sandbox.path, 'Documents'));
    await Directory(p.join(docs.path, 'downloads')).create(recursive: true);
    final victim = Directory(p.join(sandbox.path, 'victim'));
    await victim.create();
    await File(p.join(victim.path, 'sentinel')).writeAsString('test data only');
    final old = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPaths(docs.path);
    try {
      await FileService().deleteChapterPageDirectory('..', '..', 'victim');
      expect(await victim.exists(), isFalse, reason: 'Confirms out-of-root recursive deletion');
    } finally {
      PathProviderPlatform.instance = old;
      await sandbox.delete(recursive: true);
    }
  });
  test('SEC-03: raw icon identifier writes outside documents via loopback HTTP', () async {
    final sandbox = await Directory.systemTemp.createTemp('keihatsu-security-');
    final docs = Directory(p.join(sandbox.path, 'Documents'));
    await docs.create();
    final oldPaths = PathProviderPlatform.instance;
    final oldHTTP = HttpOverrides.current;
    PathProviderPlatform.instance = TestPaths(docs.path);
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.write('security-test-sentinel');
      await request.response.close();
    });
    try {
      await FileService().downloadFile('http://127.0.0.1:${server.port}/icon', 'icons/../../victim.png');
      expect(await File(p.join(sandbox.path, 'victim.png')).readAsString(), 'security-test-sentinel');
    } finally {
      await server.close(force: true);
      HttpOverrides.global = oldHTTP;
      PathProviderPlatform.instance = oldPaths;
      await sandbox.delete(recursive: true);
    }
  });
}
