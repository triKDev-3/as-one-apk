import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // On peut centraliser ici la gestion 401 (logout auto)
          if (error.response?.statusCode == 401) {
            // Token expiré ou invalide → le provider auth gérera
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Helper pour extraire un message d'erreur lisible
  static String extractError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] is String) return data['message'] as String;
      if (data['message'] is List) {
        return (data['message'] as List).join(', ');
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Serveur injoignable. Vérifiez votre connexion.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le serveur.';
    }
    return e.message ?? 'Une erreur est survenue';
  }
}
