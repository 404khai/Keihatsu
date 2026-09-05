class ApiConstants {
  // Emulator loopback to host machine.
  // static const String baseUrl = 'http://10.0.2.2:3000';

  // Local dev server — use your Mac's LAN IP (same Wi‑Fi as the test device).
  // Run: ipconfig getifaddr en0
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.232:3000',
  );

  // static const String baseUrl = 'https://keihatsu-api-production.up.railway.app';
}
