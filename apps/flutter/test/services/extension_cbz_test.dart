import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:keihatsu/services/file_service.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.root);
  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Atsumaru pages become a readable AVIF CBZ', () async {
    final root = await Directory.systemTemp.createTemp('keihatsu-cbz-');
    final previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(root.path);
    addTearDown(() async {
      PathProviderPlatform.instance = previous;
      await root.delete(recursive: true);
    });

    final service = FileService();
    final bytes = <int>[0, 0, 0, 24, 102, 116, 121, 112, 97, 118, 105, 102];
    final page = File(p.join(root.path, 'page000.avif'));
    await page.writeAsBytes(bytes);
    final cbz = await service.createCbz(
      sourceId: 'atsumaru',
      mangaId: '2VgNt',
      chapterId: '2VgNt/0S_52R',
      pagePaths: [page.path],
    );
    expect(cbz, endsWith('downloads/atsumaru/2VgNt/0S_52R.cbz'));
    final archive = ZipDecoder().decodeBytes(await File(cbz).readAsBytes(), verify: true);
    expect(archive.files.single.name, 'page001.avif');
    expect(await service.readChapterCbzPages('atsumaru', '2VgNt', '2VgNt/0S_52R'), [bytes]);
  });
}
