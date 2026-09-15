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
    } on Exception catch (e) {
      throw ApiClient.extractError(e is Exception ? e as dynamic : e);
    }
  }

  Future<TrainingVideo> create(Map<String, dynamic> data) async {
    final res = await _api.dio.post('/training-videos', data: data);
    return TrainingVideo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TrainingVideo> update(String id, Map<String, dynamic> data) async {
    final res = await _api.dio.patch('/training-videos/$id', data: data);
    return TrainingVideo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await _api.dio.delete('/training-videos/$id');
  }
}
