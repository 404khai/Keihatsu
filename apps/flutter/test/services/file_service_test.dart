import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/file_service.dart';

void main() {
  group('FileService chapter paths', () {
    final fileService = FileService();

    test('uses only the chapter leaf for nested chapter IDs', () {
      expect(
        fileService.chapterDownloadSubPath(
          sourceId: 'manhuatop',
          mangaId: 'the-regressed-mercenary',
          chapterId: 'manhua/the-regressed-mercenary/chapter-61',
        ),
        'downloads/manhuatop/the-regressed-mercenary/chapter-61',
      );
    });

    test('strips URL query parameters from chapter folder names', () {
      expect(
        fileService.chapterDownloadSubPath(
          sourceId: 'manhuatop',
          mangaId: 'series-name',
          chapterId:
              'https://manhuatop.org/manhua/series-name/chapter-61/?style=list',
        ),
        'downloads/manhuatop/series-name/chapter-61',
      );
    });

    test('places pages under the normalized chapter directory', () {
      expect(
        fileService.getChapterPageSubPath(
          sourceId: 'manhuatop',
          mangaId: 'series-name',
          chapterId: 'manhua/series-name/chapter-61',
          index: 2,
        ),
        'downloads/manhuatop/series-name/chapter-61/page002.jpg',
      );
    });

    test('places the CBZ beside the chapter directory', () {
      expect(
        fileService.getChapterCbzSubPath(
          sourceId: 'manhuatop',
          mangaId: 'series-name',
          chapterId: 'manhua/series-name/chapter-61',
        ),
        'downloads/manhuatop/series-name/chapter-61.cbz',
      );
    });
  });
}
