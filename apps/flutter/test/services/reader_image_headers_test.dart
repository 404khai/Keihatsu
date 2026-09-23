import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/reader_image_headers.dart';

void main() {
  test('MangaFire reader sends the chapter referer required by its CDN', () {
    final headers = ReaderImageHeaders.forSource(
      sourceId: 'mangafire',
      mangaUrl: 'https://mangafire.to/title/series',
      referer: 'https://mangafire.to/title/series/chapter/42',
      userAgent: 'Keihatsu test',
    );
    expect(headers?['Referer'], 'https://mangafire.to/title/series/chapter/42');
  });

  test('Atsumaru reader uses its public CDN directly', () {
    expect(
      ReaderImageHeaders.forSource(
        sourceId: 'atsumaru',
        mangaUrl: 'https://atsu.moe/manga/series',
        referer: null,
        userAgent: 'Keihatsu test',
      ),
      isNull,
    );
  });
}
