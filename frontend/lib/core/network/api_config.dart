/// Configuration de l'API AS ONE
class ApiConfig {
  /// Change cette URL selon ton environnement
  /// - Local : http://10.0.2.2:3000  (Android emulator)
  /// - Local : http://localhost:3000 (iOS simulator / Web / Desktop)
  /// - Production : https://ton-domaine.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
