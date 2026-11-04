class ApiConfig {
  // Default lokal (Laragon). 127.0.0.1 dipakai agar tidak bergantung pada
  // resolusi IPv6 "localhost" di Windows.
  // Production diatur manual lewat dart-define:
  // flutter build apk --dart-define=API_BASE_URL=https://operasional.umumcsr.com/api-bbm
  // Android emulator:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2/operasional-bbm/api
  // Perangkat fisik (LAN):
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x/operasional-bbm/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1/operasional-bbm/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
      };
}
