import 'dart:io';
import 'dart:ffi';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:http/testing.dart';
import 'package:keihatsu/models/local_models.dart';
import 'package:keihatsu/services/manga_repository.dart';
import 'package:keihatsu/services/sources_api.dart';
import 'package:keihatsu/services/library_api.dart';
import 'package:keihatsu/services/file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late Isar db;
  setUpAll(() async {
    if (Platform.isMacOS) {
      final configFile = File('.dart_tool/package_config.json').absolute;
      final config = jsonDecode(await configFile.readAsString());
      final package = (config['packages'] as List).firstWhere(
        (p) => p['name'] == 'isar_flutter_libs',
      );
      final root = configFile.uri.resolve(package['rootUri']);
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current(): '${Directory.fromUri(root).path}/macos/libisar.dylib',
        },
      );
    } else {
      await Isar.initializeIsarCore(download: true);
    }
  });
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('keihatsu-cache-test');
    db = await Isar.open(
      [LocalMangaSchema, LocalChapterSchema],
      directory: dir.path,
      name: 'cache-${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
    'cached details and chapters return without reaching the network',
    () async {
      final manga = LocalManga()
        ..ownerUserId = 'reader'
        ..sourceId = 's'
        ..mangaId = 'm'
        ..title = 'Saved title';
      final chapter = LocalChapter()
        ..ownerUserId = 'reader'
        ..sourceId = 's'
        ..mangaId = 'm'
        ..chapterId = 'c'
        ..scopedChapterKey = 'reader::s::m::c'
        ..name = 'Chapter 1'
        ..chapterNumber = 1
        ..dateUpload = 0;
      await db.writeTxn(() async {
        await db.localMangas.put(manga);
        await db.localChapters.put(chapter);
      });
      var networkCalls = 0;
      final api = SourcesApi(
        client: MockClient((_) async {
          networkCalls++;
          throw StateError('Network should not be used');
        }),
      );
      var owner = 'reader';
      final repo = MangaRepository(
        isar: db,
        api: api,
        fileService: FileService(),
        libraryApi: LibraryApi(),
        getCurrentUserId: () => owner,
      );
      expect((await repo.getMangaDetails('s', 'm'))!.title, 'Saved title');
      expect((await repo.getChapters('s', 'm')).single.name, 'Chapter 1');
      expect(networkCalls, 0);
      owner = 'another-account';
      expect(await repo.getMangaDetails('s', 'm'), isNull);
      expect(networkCalls, 1); // Never return the first account's cached title.
    },
  );
}
