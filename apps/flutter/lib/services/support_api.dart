import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'secure_api_client.dart';

class SupportApi {
  final String baseUrl;
  final http.Client _client;

  SupportApi({String? baseUrl, http.Client? client})
    : baseUrl = ApiConstants.validateBaseUrl(baseUrl ?? ApiConstants.baseUrl),
      _client = SecureApiClient(client: client);

  Future<void> reportBug({required String message, String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/support/report-bug'),
      headers: headers,
      body: json.encode({'message': message}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to send bug report: ${response.body}');
    }
  }
}
