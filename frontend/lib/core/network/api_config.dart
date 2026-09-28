/// Configuration de l'API AS ONE
class ApiConfig {
  /// URL de production (Render).
  /// Surcharge possible au build : --dart-define=API_BASE_URL=https://...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://as-one-apk.onrender.com',
  );

  /// Timeouts plus longs : Render Free peut mettre 30–60s à se réveiller
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
