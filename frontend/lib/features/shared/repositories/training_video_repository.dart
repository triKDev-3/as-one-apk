import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../models/training_video.dart';

final trainingVideoRepositoryProvider =
    Provider<TrainingVideoRepository>((ref) {
  return TrainingVideoRepository(ref.watch(apiClientProvider));
});

class TrainingVideoRepository {
  final ApiClient _api;
  TrainingVideoRepository(this._api);

  Future<List<TrainingVideo>> findAll({bool activeOnly = false}) async {
    try {
      final res = await _api.dio.get('/training-videos', queryParameters: {
        if (activeOnly) 'activeOnly': 'true',
      });
      return (res.data as List)
          .map((e) => TrainingVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<TrainingVideo> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/training-videos', data: data);
      return TrainingVideo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<TrainingVideo> update(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.patch('/training-videos/$id', data: data);
      return TrainingVideo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _api.dio.delete('/training-videos/$id');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
