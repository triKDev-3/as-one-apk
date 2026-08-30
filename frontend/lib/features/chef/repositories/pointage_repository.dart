import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PointageRepository {
  final ApiClient _api;

  PointageRepository(this._api);

  Future<Map<String, dynamic>> createPointage({
    required String siteId,
    required List<String> agentIds,
    required String type, // ARRIVEE | DEPART | PRESENCE_PERMANENCE
    String? photoUrl,
    String? notedAt,
  }) async {
    try {
      final response = await _api.dio.post(
        '/pointages',
        data: {
          'siteId': siteId,
          'agentIds': agentIds,
          'type': type,
          if (photoUrl != null) 'photoUrl': photoUrl,
          if (notedAt != null) 'notedAt': notedAt,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> getBySite(String siteId, {String? date}) async {
    try {
      final response = await _api.dio.get(
        '/pointages/site/$siteId',
        queryParameters: date != null ? {'date': date} : null,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<String> uploadPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await _api.dio.post(
        '/upload/photo',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
