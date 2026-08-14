import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PayrollRepository {
  final ApiClient _api;

  PayrollRepository(this._api);

  Future<List<dynamic>> listPeriods() async {
    try {
      final response = await _api.dio.get('/payroll/periods');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> createPeriod({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _api.dio.post('/payroll/periods', data: {
        'startDate': startDate,
        'endDate': endDate,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> getPeriod(String id) async {
    try {
      final response = await _api.dio.get('/payroll/periods/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> adjustLine({
    required String lineId,
    double? primes,
    double? retenues,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (primes != null) data['primes'] = primes;
      if (retenues != null) data['retenues'] = retenues;
      final response = await _api.dio.patch('/payroll/lines/$lineId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> validatePeriod(String periodId) async {
    try {
      await _api.dio.post('/payroll/periods/$periodId/validate');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> getVirements({
    required String periodId,
    required String siteId,
  }) async {
    try {
      final response = await _api.dio.get(
        '/payroll/periods/$periodId/site/$siteId/virements',
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
