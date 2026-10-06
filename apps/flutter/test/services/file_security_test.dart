// Actual filesystem operations use isolated temporary sentinels.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/file_service.dart';
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
  test(
    'SEC-03: crafted chapter IDs cannot delete a directory outside documents',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'keihatsu-security-',
      );
      final docs = Directory(p.join(sandbox.path, 'Documents'));
      await Directory(p.join(docs.path, 'downloads')).create(recursive: true);
      final victim = Directory(p.join(sandbox.path, 'victim'));
      await victim.create();
      await File(
        p.join(victim.path, 'sentinel'),
      ).writeAsString('test data only');
      final old = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPaths(docs.path);
      try {
        await FileService().deleteChapterPageDirectory('..', '..', 'victim');
        expect(
          await victim.exists(),
          isTrue,
          reason: 'Outside sentinel must survive',
        );
      } finally {
        PathProviderPlatform.instance = old;
        await sandbox.delete(recursive: true);
      }
    },
  );
  test('SEC-03: raw icon identifier cannot write outside documents', () async {
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
      await FileService().downloadFile(
        'http://127.0.0.1:${server.port}/icon',
        'icons/../../victim.png',
      );
      expect(await File(p.join(sandbox.path, 'victim.png')).exists(), isFalse);
    } finally {
      await server.close(force: true);
      HttpOverrides.global = oldHTTP;
      PathProviderPlatform.instance = oldPaths;
      await sandbox.delete(recursive: true);
    }
  });
  test(
    'download refuses an existing symlink leading outside storage',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'keihatsu-link-test-',
      );
      final docs = Directory(p.join(sandbox.path, 'Documents'));
      final outside = Directory(p.join(sandbox.path, 'outside'));
      await docs.create();
      await outside.create();
      await Link(p.join(docs.path, 'icons')).create(outside.path);
      final old = PathProviderPlatform.instance;
      PathProviderPlatform.instance = TestPaths(docs.path);
      try {
        expect(
          await FileService().downloadFile(
            'http://127.0.0.1:1/icon',
            'icons/victim.png',
          ),
          isNull,
        );
        expect(
          await File(p.join(outside.path, 'victim.png')).exists(),
          isFalse,
        );
      } finally {
        PathProviderPlatform.instance = old;
        await sandbox.delete(recursive: true);
      }
    },
  );
}
