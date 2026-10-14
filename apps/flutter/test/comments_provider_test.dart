import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keihatsu/providers/comments_provider.dart';

void main() {
  test(
    'network and server failures never reveal backend addresses or raw bodies',
    () async {
      final p = CommentsProvider(
        client: MockClient(
          (_) async =>
              throw Exception('SocketException https://private-api/path'),
        ),
      );
      await p.fetchComments('s', 'm', 'c', 'token');
      expect(p.error, isNot(contains('private-api')));
      final post = CommentsProvider(
        client: MockClient(
          (_) async => http.Response('https://private-api/database-trace', 500),
        ),
      );
      await expectLater(
        post.postComment('s', 'm', 'c', 'hello', 'token'),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('could not be sent') &&
                !e.toString().contains('private-api'),
          ),
        ),
      );
    },
  );
  test(
    'a late previous-chapter request cannot replace the active thread',
    () async {
      final old = Completer<http.Response>();
      final p = CommentsProvider(
        client: MockClient(
          (r) async => r.url.path.endsWith('/old')
              ? old.future
              : http.Response('[]', 200),
        ),
      );
      final first = p.fetchComments('s', 'm', 'old', null);
      await p.fetchComments('s', 'm', 'new', null);
      old.complete(http.Response('backend failure', 500));
      await first;
      expect(p.error, isNull);
      expect(p.isLoading, false);
    },
  );
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
