import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/secure_api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../services/api_constants.dart';

class CommentActionException implements Exception {
  const CommentActionException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CommentsProvider with ChangeNotifier {
  final http.Client _client;
  final bool _ownsClient;
  List<Comment> _comments = [];
  bool _isLoading = false;
  int _request = 0;
  String? _activeThread;
  bool _disposed = false;
  String? _error;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CommentsProvider({http.Client? client})
    : _client = SecureApiClient(client: client),
      _ownsClient = client == null;

  Future<void> fetchComments(
    String sourceId,
    String mangaId,
    String chapterId,
    String? token, {
    bool showLoader = true,
  }) async {
    final requestId = ++_request;
    _activeThread = '$sourceId/$mangaId/$chapterId';
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

      final response = await _client
          .get(_commentsUri(sourceId, mangaId, chapterId), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (_disposed || requestId != _request) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments = data.map((json) => Comment.fromJson(json)).toList();
        _error = null;
      } else if (response.statusCode == 404) {
        // Treat 404 as empty list
        _comments = [];
        _error = null;
      } else {
        _error = 'Comments could not be loaded. Pull to refresh or try again.';
      }
    } catch (e) {
      if (!_disposed && requestId == _request)
        _error = 'Could not connect. Please try again.';
    } finally {
      if (_disposed || requestId != _request) return;
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
    if (imagePaths.length > 5)
      throw const CommentActionException('You can attach up to 5 images.');
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
        if (await File(path).length() > 5 * 1024 * 1024) {
          throw const CommentActionException(
            'That image is too large. Choose a smaller image.',
          );
        }
        final ext = path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
            contentType: MediaType('image', switch (ext) {
              'png' => 'png',
              'webp' => 'webp',
              _ => 'jpeg',
            }),
          ),
        );
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 201) {
        // Refresh comments
        if (_activeThread == '$sourceId/$mangaId/$chapterId') {
          await fetchComments(
            sourceId,
            mangaId,
            chapterId,
            token,
            showLoader: false,
          );
        }
      } else {
        throw CommentActionException(
          response.statusCode == 401
              ? 'Please sign in again to comment.'
              : 'Your comment could not be sent. Please try again.',
        );
      }
    } on CommentActionException {
      rethrow;
    } catch (_) {
      throw const CommentActionException(
        'Could not send your comment. Check your connection and try again.',
      );
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
        throw const CommentActionException(
          'Could not update your like. Please try again.',
        );
      }
    } catch (_) {
      throw const CommentActionException(
        'Could not update your like. Please try again.',
      );
    }
  }

  Future<List<User>> searchMentionUsers(String token, String query) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/user/profile/mentions',
    ).replace(queryParameters: {'query': query});
    final response = await _client
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200)
      throw const CommentActionException(
        'Could not find users. Please try again.',
      );
    return (json.decode(response.body) as List)
        .map((u) => User.fromJson(u))
        .toList();
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
    _disposed = true;
    ++_request;
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
