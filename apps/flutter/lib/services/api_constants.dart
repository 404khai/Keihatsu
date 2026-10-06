import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode
        ? 'http://192.168.1.232:3000'
        : 'https://keihatsu-api-production.up.railway.app',
  );

  static String get baseUrl => validateBaseUrl(_configuredBaseUrl);

  /// Runtime validation also protects caller-supplied API origins in release.
  static String validateBaseUrl(
    String value, {
    bool allowInsecureHTTP = kDebugMode,
  }) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(allowInsecureHTTP && uri.scheme == 'http')) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Set API_BASE_URL to an HTTPS API address for release builds.',
      );
    }
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }
}
