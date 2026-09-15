import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/training_video.dart';

final trainingVideoRepositoryProvider = Provider<TrainingVideoRepository>((ref) {
  return TrainingVideoRepository(ref.watch(apiClientProvider));
});

class TrainingVideoRepository {
  final Dio _dio;
  TrainingVideoRepository(this._dio);

  Future<List<TrainingVideo>> findAll({bool activeOnly = false}) async {
    final res = await _dio.get('/training-videos', queryParameters: {
      if (activeOnly) 'activeOnly': 'true',
    });
    return (res.data as List).map((e) => TrainingVideo.fromJson(e)).toList();
  }

  Future<TrainingVideo> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/training-videos', data: data);
    return TrainingVideo.fromJson(res.data);
  }

  Future<TrainingVideo> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/training-videos/$id', data: data);
    return TrainingVideo.fromJson(res.data);
  }

  Future<void> remove(String id) async {
    await _dio.delete('/training-videos/$id');
  }
}
