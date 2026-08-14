import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import 'models/user_model.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthRepository(this._api, this._storage);

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final userJson = data['user'] as Map<String, dynamic>;

      await _storage.saveToken(token);
      await _storage.saveUserJson(jsonEncode(userJson));

      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<UserModel?> getSavedUser() async {
    final jsonStr = await _storage.getUserJson();
    final token = await _storage.getToken();
    if (jsonStr == null || token == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
