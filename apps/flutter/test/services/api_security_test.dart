import 'package:flutter_test/flutter_test.dart';
import 'package:keihatsu/services/api_constants.dart';
import 'package:keihatsu/services/auth_api.dart';
import 'package:keihatsu/services/secure_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('release API policy rejects insecure and malformed configuration', () {
    for (final value in [
      '',
      'http://localhost:3000',
      'file:///tmp/api',
      'https://user:secret@example.test',
      'https://example.test?token=secret',
      'https://example.test#fragment',
    ]) {
      expect(
        () => ApiConstants.validateBaseUrl(value, allowInsecureHTTP: false),
        throwsArgumentError,
      );
    }
    expect(
      ApiConstants.validateBaseUrl(
        ' https://example.test/api/ ',
        allowInsecureHTTP: false,
      ),
      'https://example.test/api',
    );
  });
  test(
    'debug LAN servers remain supported and injected origins are validated',
    () {
      expect(
        ApiConstants.validateBaseUrl(
          'http://192.168.1.10:3000',
          allowInsecureHTTP: true,
        ),
        'http://192.168.1.10:3000',
      );
      expect(
        () => AuthApi(baseUrl: 'https://user:password@example.test'),
        throwsArgumentError,
      );
    },
  );
  test(
    'release transport rejects HTTP and does not forward redirect credentials',
    () async {
      var calls = 0;
      final client = SecureApiClient(
        allowInsecureHTTP: false,
        client: MockClient((request) async {
          calls++;
          expect(request.followRedirects, false);
          return http.Response(
            '',
            307,
            headers: {'location': 'http://other.test/login'},
          );
        }),
      );
      await expectLater(
        client.get(
          Uri.parse('http://example.test'),
          headers: {'Authorization': 'Bearer fake'},
        ),
        throwsArgumentError,
      );
      expect(calls, 0);
      final response = await client.post(
        Uri.parse('https://example.test/auth/google'),
        body: 'fake-token',
      );
      expect(response.statusCode, 307);
      expect(calls, 1);
    },
  );
}
