import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/comment.dart';
import '../services/api_constants.dart';

class CommentsProvider with ChangeNotifier {
  final http.Client _client;
  final bool _ownsClient;
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CommentsProvider({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  Future<void> fetchComments(
    String sourceId,
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

      final response = await _client.get(
        _commentsUri(sourceId, mangaId, chapterId),
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
    String sourceId,
    String mangaId,
    String chapterId,
    String content,
    String token, {
    String? parentId,
    List<String> imagePaths = const [],
  }) async {
    try {
      final uri = _commentsUri(sourceId, mangaId, chapterId);
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

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Refresh comments
        await fetchComments(sourceId, mangaId, chapterId, token);
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
    String sourceId,
    String mangaId,
    String chapterId,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/comments/like/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh comments seamlessly
        await fetchComments(
          sourceId,
          mangaId,
          chapterId,
          token,
          showLoader: false,
        );
      } else {
        throw Exception('Failed to like: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Uri _commentsUri(String sourceId, String mangaId, String chapterId) =>
      Uri.parse(ApiConstants.baseUrl).replace(
        pathSegments: [
          ...Uri.parse(
            ApiConstants.baseUrl,
          ).pathSegments.where((segment) => segment.isNotEmpty),
          'comments',
          'source',
          sourceId,
          mangaId,
          chapterId,
        ],
      );

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
