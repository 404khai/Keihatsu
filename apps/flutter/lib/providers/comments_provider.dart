import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/comment.dart';
import '../services/api_constants.dart';

class CommentsProvider with ChangeNotifier {
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComments(
    String mangaId,
    String chapterId,
    String? token, {
    bool showLoader = true,
  }) async {
    if (showLoader) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final encodedMangaId = Uri.encodeComponent(mangaId);
      final encodedChapterId = Uri.encodeComponent(chapterId);

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/comments/$encodedMangaId/$encodedChapterId',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments = data.map((json) => Comment.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // Treat 404 as empty list
        _comments = [];
      } else {
        _error = 'Failed to load comments: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoader) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> postComment(
    String mangaId,
    String chapterId,
    String content,
    String token, {
    String? parentId,
    List<String> imagePaths = const [],
  }) async {
    try {
      final encodedMangaId = Uri.encodeComponent(mangaId);
      final encodedChapterId = Uri.encodeComponent(chapterId);

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/comments/$encodedMangaId/$encodedChapterId',
      );
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      if (content.isNotEmpty) {
        request.fields['content'] = content;
      }

      if (parentId != null) {
        request.fields['parentId'] = parentId;
      }

      for (var path in imagePaths) {
        request.files.add(await http.MultipartFile.fromPath('images', path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Refresh comments
        await fetchComments(mangaId, chapterId, token);
      } else {
        throw Exception(
          'Failed to post comment: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeComment(
    String commentId,
    String token,
    String mangaId,
    String chapterId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/comments/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh comments seamlessly
        await fetchComments(mangaId, chapterId, token, showLoader: false);
      } else {
        throw Exception('Failed to like: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
