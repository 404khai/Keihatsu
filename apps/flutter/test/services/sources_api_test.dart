import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/sources_api.dart';

void main() {
  group('SourcesApi download image URL', () {
    final api = SourcesApi(baseUrl: 'http://192.168.1.10:3000');

    test('proxies ManhuaTop images through the API', () {
      final result = api.getDownloadImageUrl(
        sourceId: 'manhuatop',
        imageUrl: 'https://s3.manhuatop.org/series/chapter/page-1.jpg',
        referer: 'https://manhuatop.org/manhua/series/chapter-1/',
      );
      final uri = Uri.parse(result);

      expect(uri.path, '/sources/proxy/image');
      expect(
        uri.queryParameters['url'],
        'https://s3.manhuatop.org/series/chapter/page-1.jpg',
      );
      expect(
        uri.queryParameters['referer'],
        'https://manhuatop.org/manhua/series/chapter-1/',
      );
    });

    test('leaves other extension image URLs unchanged', () {
      const imageUrl = 'https://example.com/chapter/page-1.jpg';

      expect(
        api.getDownloadImageUrl(
          sourceId: 'other-source',
          imageUrl: imageUrl,
          referer: 'https://example.com/chapter-1/',
        ),
        imageUrl,
      );
    });
  });
}
