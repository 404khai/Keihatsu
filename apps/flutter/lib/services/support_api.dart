import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class SupportApi {
  final String baseUrl;

  SupportApi({this.baseUrl = ApiConstants.baseUrl});

  Future<void> reportBug({required String message, String? token}) async {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/support/report-bug'),
      headers: headers,
      body: json.encode({'message': message}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to send bug report: ${response.body}');
    }
  }
}
