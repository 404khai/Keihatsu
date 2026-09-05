import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class LibraryApi {
  final String baseUrl;
  LibraryApi({this.baseUrl = ApiConstants.baseUrl});

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // --- Library Endpoints ---

  Future<http.Response> getLibrary({
    required String token,
    bool? filterDownloaded,
    bool? filterUnread,
    bool? filterStarted,
    bool? filterBookmarked,
    bool? filterCompleted,
    String? sortBy,
    String? order,
    String? search,
  }) async {
    final queryParams = {
      if (filterDownloaded != null)
        'filter_downloaded': filterDownloaded.toString(),
      if (filterUnread != null) 'filter_unread': filterUnread.toString(),
      if (filterStarted != null) 'filter_started': filterStarted.toString(),
      if (filterBookmarked != null)
        'filter_bookmarked': filterBookmarked.toString(),
      if (filterCompleted != null)
        'filter_completed': filterCompleted.toString(),
      if (sortBy != null) 'sort_by': sortBy,
      if (order != null) 'order': order,
      if (search != null) 'search': search,
    };

    final uri = Uri.parse(
      '$baseUrl/user/library',
    ).replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers(token));
  }

  Future<http.Response> addMangaToLibrary(
      String token,
      Map<String, dynamic> mangaData, {
        List<String>? categories,
      }) async {
    // Note: Spec doesn't include categories in POST body, but we keep the parameter for compatibility.
    // If categories are needed, they should be set via assignMangaToCategory after this call.
    return await http.post(
      Uri.parse('$baseUrl/user/library'),
      headers: _headers(token),
      body: json.encode(mangaData),
    );
  }

  Future<http.Response> updateLibraryEntry(
      String token,
      String id,
      Map<String, dynamic> updateData,
      ) async {
    return await http.put(
      Uri.parse('$baseUrl/user/library/$id'),
      headers: _headers(token),
      body: json.encode(updateData),
    );
  }

  // Alias for backward compatibility
  Future<http.Response> deleteMangaFromLibrary(String token, String id) =>
      deleteLibraryEntry(token, id);

  Future<http.Response> deleteLibraryEntry(String token, String id) async {
    return await http.delete(
      Uri.parse('$baseUrl/user/library/$id'),
      headers: _headers(token),
    );
  }

  // --- Categories Endpoints ---

  Future<http.Response> getCategories(
      String token, {
        bool includeCount = false,
      }) async {
    final queryParams = {if (includeCount) 'include_count': 'true'};
    final uri = Uri.parse(
      '$baseUrl/user/categories',
    ).replace(queryParameters: queryParams);
    return await http.get(uri, headers: _headers(token));
  }

  Future<http.Response> createCategory(String token, String name) async {
    return await http.post(
      Uri.parse('$baseUrl/user/categories'),
      headers: _headers(token),
      body: json.encode({'name': name}),
    );
  }

  Future<http.Response> updateCategory(
      String token,
      String id,
      String name,
      ) async {
    return await http.put(
      Uri.parse('$baseUrl/user/categories/$id'),
      headers: _headers(token),
      body: json.encode({'name': name}),
    );
  }

  Future<http.Response> deleteCategory(String token, String id) async {
    return await http.delete(
      Uri.parse('$baseUrl/user/categories/$id'),
      headers: _headers(token),
    );
  }

  Future<http.Response> assignMangaToCategory(
      String token,
      String mangaId,
      String categoryId,
      ) async {
    return await http.post(
      Uri.parse('$baseUrl/manga/$mangaId/category/$categoryId'),
      headers: _headers(token),
    );
  }

  // --- User Preferences Endpoints ---

  Future<http.Response> getPreferences(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/user/preferences'),
      headers: _headers(token),
    );
  }

  Future<http.Response> updatePreferences(
      String token,
      Map<String, dynamic> preferences,
      ) async {
    return await http.put(
      Uri.parse('$baseUrl/user/preferences'),
      headers: _headers(token),
      body: json.encode(preferences),
    );
  }

  // --- Download Endpoint ---
  Future<http.Response> downloadChapter({
    required String token,
    required String sourceId,
    required String mangaId,
    required String chapterId,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl/downloads/process'),
      headers: _headers(token),
      body: json.encode({
        'sourceId': sourceId,
        'mangaId': mangaId,
        'chapterId': chapterId,
      }),
    );
  }

  // --- History Endpoints ---
  Future<http.Response> syncHistory({
    required String token,
    required String mangaId,
    required String sourceId,
    required String chapterId,
    required int pageNumber,
    required DateTime lastReadAt,
    String? title,
    String? thumbnailUrl,
    String? author,
    String? chapterName,
    double? chapterNumber,
    bool? isBookmarked,
    bool? isRead,
    int? readingTimeMs,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl/history/sync'),
      headers: _headers(token),
      body: json.encode({
        'mangaId': mangaId,
        'sourceId': sourceId,
        'chapterId': chapterId,
        if (title != null) 'title': title,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (author != null) 'author': author,
        if (chapterName != null) 'chapterName': chapterName,
        if (chapterNumber != null) 'chapterNumber': chapterNumber,
        'pageNumber': pageNumber,
        'lastReadAt': lastReadAt.toIso8601String(),
        if (isBookmarked != null) 'isBookmarked': isBookmarked,
        if (isRead != null) 'isRead': isRead,
        if (readingTimeMs != null) 'readingTimeMs': readingTimeMs,
      }),
    );
  }

  Future<http.Response> getHistory(
      String token, {
        int page = 1,
        int limit = 50,
      }) async {
    final uri = Uri.parse('$baseUrl/history').replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    return await http.get(uri, headers: _headers(token));
  }

  Future<http.Response> deleteHistoryEntry(String token, String mangaId) async {
    return await http.delete(
      Uri.parse('$baseUrl/history/$mangaId'),
      headers: _headers(token),
    );
  }
}
