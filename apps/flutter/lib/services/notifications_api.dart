import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class InboxNotification {
  final String id, type, title, body, deepLink;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? sourceId, mangaId, chapterId, commentId, threadId;

  const InboxNotification({required this.id, required this.type, required this.title,
    required this.body, required this.deepLink, required this.createdAt,
    this.readAt, this.sourceId, this.mangaId, this.chapterId, this.commentId, this.threadId});

  bool get isRead => readAt != null;
  InboxNotification withReadAt(DateTime? value) => InboxNotification(id: id, type: type,
    title: title, body: body, deepLink: deepLink, createdAt: createdAt, readAt: value,
    sourceId: sourceId, mangaId: mangaId, chapterId: chapterId,
    commentId: commentId, threadId: threadId);

  factory InboxNotification.fromJson(Map<String, dynamic> json) => InboxNotification(
    id: json['id'] as String, type: json['type'] as String,
    title: json['title'] as String, body: json['body'] as String,
    deepLink: json['deepLink'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    sourceId: json['sourceId'] as String?, mangaId: json['mangaId'] as String?,
    chapterId: json['chapterId'] as String?, commentId: json['commentId'] as String?,
    threadId: json['threadId'] as String?,
  );
}

class InboxPage {
  final List<InboxNotification> items;
  final String? nextCursor;
  InboxPage(this.items, this.nextCursor);
}

class NotificationsApi {
  final String baseUrl;
  final http.Client client;
  NotificationsApi({this.baseUrl = ApiConstants.baseUrl, http.Client? client}) : client = client ?? http.Client();

  Future<dynamic> _request(String method, String path, String token, [Object? body]) async {
    final response = await client.send(http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({'Authorization': 'Bearer $token', 'Content-Type': 'application/json'})
      ..body = body == null ? '' : jsonEncode(body));
    final payload = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Notifications request failed (${response.statusCode})');
    }
    return payload.isEmpty ? <String, dynamic>{} : jsonDecode(payload);
  }

  Future<InboxPage> list(String token, {String? cursor, String? category, bool? unread}) async {
    final query = <String, String>{if (cursor != null) 'cursor': cursor,
      if (category != null && category != 'ALL') 'category': category,
      if (unread != null) 'unread': '$unread'};
    final uri = Uri(path: '/notifications', queryParameters: query.isEmpty ? null : query);
    final json = await _request('GET', uri.toString(), token) as Map<String, dynamic>;
    return InboxPage((json['items'] as List).map((item) => InboxNotification.fromJson(item as Map<String, dynamic>)).toList(),
      json['nextCursor'] as String?);
  }

  Future<int> unreadCount(String token) async =>
    (await _request('GET', '/notifications/unread-count', token) as Map<String, dynamic>)['count'] as int;
  Future<void> markRead(String token, String id) async =>
    _request('PATCH', '/notifications/${Uri.encodeComponent(id)}/read', token);
  Future<void> readAll(String token) async => _request('POST', '/notifications/read-all', token);
  Future<void> delete(String token, String id) async =>
    _request('DELETE', '/notifications/${Uri.encodeComponent(id)}', token);
  Future<Map<String, dynamic>> preferences(String token) async =>
    (await _request('GET', '/notifications/preferences', token)) as Map<String, dynamic>;
  Future<void> updatePreferences(String token, Map<String, bool> values) async =>
    _request('PATCH', '/notifications/preferences', token, values);
  Future<void> register(String token, String installationId, String pushToken, String appVersion) async =>
    _request('POST', '/notifications/devices', token, {
      'installationId': installationId, 'platform': 'ANDROID', 'token': pushToken, 'appVersion': appVersion});
  Future<void> unregister(String token, String installationId) async =>
    _request('DELETE', '/notifications/devices/${Uri.encodeComponent(installationId)}', token);
}
