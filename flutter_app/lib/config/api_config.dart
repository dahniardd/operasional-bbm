class ApiConfig {
  // Default lokal (Laragon). Production diatur manual lewat dart-define:
  // flutter build apk --dart-define=API_BASE_URL=https://operasional.umumcsr.com/api-bbm
  // Android emulator:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2/operasional_bbm/api
  // Perangkat fisik (LAN):
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x/operasional_bbm/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/operasional_bbm/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
      };
}
