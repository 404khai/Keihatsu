import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keihatsu/providers/comments_provider.dart';

void main() {
  test('loads comments with the complete source chapter identity', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.pathSegments, [
        'comments',
        'source',
        'weebcentral',
        'manga/with spaces',
        'chapter#1',
      ]);
      expect(request.headers['Authorization'], 'Bearer session');
      return http.Response(jsonEncode(<Object>[]), 200);
    });
    final provider = CommentsProvider(client: client);

    await provider.fetchComments(
      'weebcentral',
      'manga/with spaces',
      'chapter#1',
      'session',
    );

    expect(provider.comments, isEmpty);
    expect(provider.error, isNull);
  });
}
