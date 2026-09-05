import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/source.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import 'api_constants.dart';

class SourcesApi {
  final String baseUrl;
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _heavySourceTimeout = Duration(seconds: 30);

  SourcesApi({this.baseUrl = ApiConstants.baseUrl});

  String getDownloadImageUrl({
    required String sourceId,
    required String imageUrl,
    required String referer,
  }) {
    if (sourceId.toLowerCase() != 'manhuatop') return imageUrl;

    return Uri.parse('$baseUrl/sources/proxy/image')
        .replace(queryParameters: {'url': imageUrl, 'referer': referer})
        .toString();
  }

  Duration _timeoutForSource(String sourceId) {
    return sourceId.toLowerCase() == 'batcave'
        ? _heavySourceTimeout
        : _defaultTimeout;
  }

  Future<List<Source>> getSources() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sources')).timeout(_defaultTimeout);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Source.fromJson(json)).toList();
      }
      throw Exception('Failed to load sources: ${response.statusCode}');
    } catch (e) {
      print('SourcesApi.getSources error: $e');
      rethrow;
    }
  }

  Future<MangasPage> getMangaList(String sourceId, String type, {int page = 1, String? q}) async {
    try {
      final queryParams = {
        'type': type,
        'page': page.toString(),
      };
      if (q != null) queryParams['q'] = q;

      final uri = Uri.parse('$baseUrl/sources/$sourceId/manga').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(_timeoutForSource(sourceId));

      if (response.statusCode == 200) {
        return MangasPage.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load manga list: ${response.statusCode}');
    } catch (e) {
      print('SourcesApi.getMangaList error: $e');
      rethrow;
    }
  }

  Future<Manga> getMangaDetails(String sourceId, String mangaId) async {
    try {
      final encodedMangaId = Uri.encodeComponent(mangaId);
      final response = await http
          .get(Uri.parse('$baseUrl/sources/$sourceId/manga/$encodedMangaId'))
          .timeout(_timeoutForSource(sourceId));
      if (response.statusCode == 200) {
        return Manga.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load manga details: ${response.statusCode}');
    } catch (e) {
      print('SourcesApi.getMangaDetails error: $e');
      rethrow;
    }
  }

  Future<List<Chapter>> getChapters(String sourceId, String mangaId) async {
    try {
      final encodedMangaId = Uri.encodeComponent(mangaId);
      final response = await http
          .get(
        Uri.parse('$baseUrl/sources/$sourceId/manga/$encodedMangaId/chapters'),
      )
          .timeout(_timeoutForSource(sourceId));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Chapter.fromJson(json)).toList();
      }
      throw Exception('Failed to load chapters: ${response.statusCode}');
    } catch (e) {
      print('SourcesApi.getChapters error: $e');
      rethrow;
    }
  }

  Future<List<ReaderPage>> getPages(String sourceId, String chapterId) async {
    try {
      final encodedChapterId = Uri.encodeComponent(chapterId);
      final response = await http
          .get(Uri.parse('$baseUrl/sources/$sourceId/chapters/$encodedChapterId/pages'))
          .timeout(_timeoutForSource(sourceId));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => ReaderPage.fromJson(json)).toList();
      }
      throw Exception('Failed to load pages: ${response.statusCode}');
    } catch (e) {
      print('SourcesApi.getPages error: $e');
      rethrow;
    }
  }
}
