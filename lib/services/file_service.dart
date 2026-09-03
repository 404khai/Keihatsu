import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class FileService {
  final Dio _dio = Dio();
  static const String _publicDirName = 'Keihatsu';

  /// Returns the base directory based on the subPath.
  /// If the path starts with 'downloads/', it targets external storage (visible).
  /// Otherwise, it defaults to the app's internal documents directory.
  Future<Directory> _getBaseDirectory(String subPath) async {
    if (subPath.startsWith('downloads/')) {
      if (Platform.isAndroid) {
        // Target /storage/emulated/0/Keihatsu
        try {
          final directory = Directory('/storage/emulated/0/$_publicDirName');
          // Check if we can actually access it
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          return directory;
        } catch (e) {
          print('Error accessing/creating public directory: $e');
          // Fallback to internal documents directory if external access fails
          // This ensures the app doesn't crash even if permissions are wonky
          return getApplicationDocumentsDirectory();
        }
      }
    }
    return getApplicationDocumentsDirectory();
  }

  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // 1. Android 11+ (API 30+): Manage External Storage
    // First, check if it's already granted.
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // If denied or restricted, request it.
    if (await Permission.manageExternalStorage.status.isDenied ||
        await Permission.manageExternalStorage.status.isRestricted ||
        await Permission.manageExternalStorage.status.isPermanentlyDenied) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
    }

    // 2. Android 10 and below: Legacy Storage Permissions
    // Only check this if manageExternalStorage didn't work (or on older OS).
    // Note: On Android 13+, this will likely return denied if not using scoped storage properly,
    // but manageExternalStorage covers the "All files access" case.
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<String> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Directory> getDownloadsDirectory() async {
    final baseDirectory = await _getBaseDirectory('downloads/');
    final downloadsDirectory = Directory(
      p.join(baseDirectory.path, 'downloads'),
    );
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    return downloadsDirectory;
  }

  Future<String> getDownloadsDirectoryPath() async {
    final directory = await getDownloadsDirectory();
    return directory.path;
  }

  Future<int> getDownloadsSize() async {
    final directory = await getDownloadsDirectory();
    if (!await directory.exists()) return 0;

    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> cleanupArchivedChapterDirectories() async {
    final downloadsDirectory = await getDownloadsDirectory();

    await for (final sourceEntity in downloadsDirectory.list()) {
      if (sourceEntity is! Directory) continue;

      await for (final mangaEntity in sourceEntity.list()) {
        if (mangaEntity is! Directory) continue;

        final entries = await mangaEntity.list().toList();
        final archivedChapterNames = entries
            .whereType<File>()
            .where((file) => p.extension(file.path).toLowerCase() == '.cbz')
            .map((file) => p.basenameWithoutExtension(file.path))
            .toSet();

        for (final entry in entries.whereType<Directory>()) {
          if (archivedChapterNames.contains(p.basename(entry.path))) {
            await entry.delete(recursive: true);
          }
        }
      }
    }
  }

  Future<String> createCbz({
    required String sourceId,
    required String mangaId,
    required String chapterId,
    required List<String> pagePaths,
  }) async {
    if (pagePaths.isEmpty) {
      throw Exception('Cannot create an empty CBZ archive');
    }

    final archive = Archive();
    for (var i = 0; i < pagePaths.length; i++) {
      final page = File(pagePaths[i]);
      if (!await page.exists()) {
        throw Exception('Downloaded page ${i + 1} is missing');
      }

      final bytes = await page.readAsBytes();
      final extension = p.extension(page.path).isEmpty
          ? '.jpg'
          : p.extension(page.path);
      final filename = 'page${(i + 1).toString().padLeft(3, '0')}$extension';
      archive.addFile(ArchiveFile(filename, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);

    final subPath = getChapterCbzSubPath(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
    );
    final baseDir = await _getBaseDirectory('downloads/');
    final output = File(p.join(baseDir.path, subPath));
    final partialOutput = File('${output.path}.part');
    await output.parent.create(recursive: true);

    if (await partialOutput.exists()) {
      await partialOutput.delete();
    }
    await partialOutput.writeAsBytes(encoded, flush: true);

    if (!await partialOutput.exists() || await partialOutput.length() == 0) {
      throw Exception('Failed to write the CBZ archive');
    }

    if (await output.exists()) {
      await output.delete();
    }
    await partialOutput.rename(output.path);

    if (!await output.exists() || await output.length() == 0) {
      throw Exception('CBZ archive was not saved');
    }
    return output.path;
  }

  Future<String?> downloadFile(
    String url,
    String subPath, {
    String? referer,
  }) async {
    try {
      // Ensure permissions are granted if writing to external storage
      if (subPath.startsWith('downloads/') && Platform.isAndroid) {
        final hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          print('Storage permission denied for download: $subPath');
          return null;
        }
      }

      final baseDir = await _getBaseDirectory(subPath);

      // If the path starts with 'downloads/', we remove that prefix to avoid double nesting
      // inside the Keihatsu folder if we want Keihatsu/sourceId/...
      // BUT current logic is: subPath = downloads/sourceId/...
      // So if baseDir is .../Keihatsu, we probably want .../Keihatsu/downloads/sourceId/...
      // OR .../Keihatsu/sourceId/...
      // The user said "land under a Keihatsu folder".
      // Let's keep the 'downloads' folder inside Keihatsu for structure: Keihatsu/downloads/...
      // So fullPath = baseDir.path + subPath.

      // However, if _getBaseDirectory returns /storage/emulated/0/Keihatsu
      // and subPath is downloads/..., then result is /storage/emulated/0/Keihatsu/downloads/...
      // This is fine.

      // If _getBaseDirectory returns internal AppDocs, result is AppDocs/downloads/...
      // This is also consistent.

      final fullPath = p.join(baseDir.path, subPath);
      final file = File(fullPath);

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final effectiveReferer = referer == null || referer.trim().isEmpty
          ? _buildReferer(url)
          : referer;
      await _dio.download(
        url,
        fullPath,
        deleteOnError: true,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36',
            'Referer': effectiveReferer,
            'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );
      print('DEBUG: File downloaded to: $fullPath');
      return fullPath;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }

  String _buildReferer(String url) {
    try {
      final uri = Uri.parse(url);
      final lowerHost = uri.host.toLowerCase();

      if (lowerHost.contains('batcave')) {
        return 'https://batcave.biz/';
      }

      return uri.origin;
    } catch (_) {
      return 'https://google.com';
    }
  }

  Future<String> getSourceIconPath(String sourceId) async {
    final appDir = await getAppDirectory();
    return p.join(appDir, 'icons', '$sourceId.png');
  }

  Future<String> getMangaThumbnailPath(String sourceId, String mangaId) async {
    final appDir = await getAppDirectory();
    return p.join(appDir, 'thumbnails', sourceId, '$mangaId.jpg');
  }

  Future<String> getChapterPagePath(
    String sourceId,
    String mangaId,
    String chapterId,
    int index,
  ) async {
    final subPath = getChapterPageSubPath(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
      index: index,
    );
    final baseDir = await _getBaseDirectory(subPath);
    return p.join(baseDir.path, subPath);
  }

  Future<String> getChapterCbzPath(
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    final subPath = getChapterCbzSubPath(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
    );
    final baseDir = await _getBaseDirectory('downloads/');
    return p.join(baseDir.path, subPath);
  }

  Future<List<Uint8List>> readChapterCbzPages(
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    final archivePath = await getChapterCbzPath(sourceId, mangaId, chapterId);
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) return const [];

    final archive = ZipDecoder().decodeBytes(
      await archiveFile.readAsBytes(),
      verify: true,
    );
    final imageFiles = archive.files.where((file) {
      if (!file.isFile) return false;
      final extension = p.extension(file.name).toLowerCase();
      return const {
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.gif',
      }.contains(extension);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return imageFiles.map((file) => file.content).toList(growable: false);
  }

  String chapterDownloadSubPath({
    required String sourceId,
    required String mangaId,
    required String chapterId,
  }) {
    return p.join(
      'downloads',
      _safeComponent(sourceId),
      _safeComponent(mangaId),
      _chapterPathComponent(chapterId),
    );
  }

  String getChapterPageSubPath({
    required String sourceId,
    required String mangaId,
    required String chapterId,
    required int index,
  }) {
    return p.join(
      chapterDownloadSubPath(
        sourceId: sourceId,
        mangaId: mangaId,
        chapterId: chapterId,
      ),
      'page${index.toString().padLeft(3, '0')}.jpg',
    );
  }

  String getChapterCbzSubPath({
    required String sourceId,
    required String mangaId,
    required String chapterId,
  }) {
    return '${chapterDownloadSubPath(sourceId: sourceId, mangaId: mangaId, chapterId: chapterId)}.cbz';
  }

  String _safeComponent(String value) {
    return value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  String _chapterPathComponent(String chapterId) {
    final normalized = chapterId.replaceAll('\\', '/');
    final withoutQuery = normalized.split(RegExp(r'[?#]')).first;
    final segments = withoutQuery
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    final leaf = segments.isEmpty ? chapterId : segments.last;
    final safeLeaf = _safeComponent(leaf);
    return safeLeaf.isEmpty ? 'chapter' : safeLeaf;
  }

  Future<void> deleteChapterPageDirectory(
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    final chapterSubPath = chapterDownloadSubPath(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
    );
    final baseDir = await _getBaseDirectory(chapterSubPath);
    final chapterDir = Directory(p.join(baseDir.path, chapterSubPath));
    if (await chapterDir.exists()) {
      await chapterDir.delete(recursive: true);
    }
  }

  Future<void> deleteChapter(
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    final chapterSubPath = chapterDownloadSubPath(
      sourceId: sourceId,
      mangaId: mangaId,
      chapterId: chapterId,
    );
    await deleteChapterPageDirectory(sourceId, mangaId, chapterId);
    final baseDir = await _getBaseDirectory(chapterSubPath);

    final baseDirForArchive = await _getBaseDirectory('downloads/');
    final cbzPath = p.join(
      baseDirForArchive.path,
      getChapterCbzSubPath(
        sourceId: sourceId,
        mangaId: mangaId,
        chapterId: chapterId,
      ),
    );
    final cbzFile = File(cbzPath);
    if (await cbzFile.exists()) {
      await cbzFile.delete();
    }

    // Check if manga folder is empty and delete if so
    final mangaSubPath = p.dirname(chapterSubPath);
    final mangaDir = Directory(p.join(baseDir.path, mangaSubPath));
    if (await mangaDir.exists()) {
      final entities = await mangaDir.list().toList();
      if (entities.isEmpty) {
        await mangaDir.delete();
      }
    }
  }
}
