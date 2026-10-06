import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API endpoints return their response directly. Do not automatically forward
/// credentials or login payloads to a different URL through a redirect.
class SecureApiClient extends http.BaseClient {
  SecureApiClient({http.Client? client, this.allowInsecureHTTP = kDebugMode})
    : _client = client ?? http.Client();

  final http.Client _client;
  final bool allowInsecureHTTP;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.scheme != 'https' &&
        !(allowInsecureHTTP && request.url.scheme == 'http')) {
      throw ArgumentError('API requests require HTTPS in release builds.');
    }
    request.followRedirects = false;
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
