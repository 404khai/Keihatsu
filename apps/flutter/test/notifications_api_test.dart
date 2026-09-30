import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keihatsu/services/notifications_api.dart';

void main() {
  test('maps a cursor page and sends authenticated filters', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer session');
      expect(request.url.queryParameters['category'], 'COMMENTS');
      return http.Response(jsonEncode({
        'items': [{ 'id': 'n1', 'type': 'COMMENT_REPLY', 'title': 'Reply',
          'body': 'Open the conversation', 'deepLink': 'keihatsu://comment/s/m/c/n1',
          'createdAt': '2026-09-30T10:00:00.000Z', 'readAt': null,
          'sourceId': 's', 'mangaId': 'm', 'chapterId': 'c', 'commentId': 'n1' }],
        'nextCursor': 'n1',
      }), 200);
    });
    final page = await NotificationsApi(baseUrl: 'https://example.test', client: client)
      .list('session', category: 'COMMENTS');
    expect(page.nextCursor, 'n1');
    expect(page.items.single.isRead, false);
    expect(page.items.single.chapterId, 'c');
  });

  test('sends deletion to the owner endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/notifications/n1');
      expect(request.headers['Authorization'], 'Bearer session');
      return http.Response('{"success":true}', 200);
    });
    await NotificationsApi(baseUrl: 'https://example.test', client: client).delete('session', 'n1');
  });
}
