import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:keihatsu/services/auth_api.dart';

void main() {
  test(
    'failed sign-in never includes a raw backend payload in its error',
    () async {
      final api = AuthApi(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          expect(request.url.path, '/auth/google');
          return http.Response('private@example.test secret-token', 500);
        }),
      );
      try {
        await api.loginWithGoogle('fake-id-token');
        fail('Expected failed sign-in');
      } catch (error) {
        expect(error.toString(), contains('500'));
        expect(error.toString(), isNot(contains('private@example.test')));
        expect(error.toString(), isNot(contains('secret-token')));
      }
    },
  );
  test(
    'account restore distinguishes expired sessions from temporary failure',
    () async {
      for (final status in [401, 503]) {
        final api = AuthApi(
          baseUrl: 'https://example.test',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          api.getMe('fake-session'),
          throwsA(
            isA<AuthApiException>().having(
              (error) => error.statusCode,
              'status',
              status,
            ),
          ),
        );
      }
    },
  );
}
