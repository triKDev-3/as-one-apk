import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class MaterialItem {
  final String id;
  final String name;
  final String category;
  final double unitPrice;

  MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MaterialRepository {
  final ApiClient _api;

  MaterialRepository(this._api);

  Future<List<MaterialItem>> listItems({String? category}) async {
    try {
      final response = await _api.dio.get(
        '/material/items',
        queryParameters: category != null ? {'category': category} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => MaterialItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> materialOut({
    required String siteId,
    required String itemId,
    required int quantity,
    String? notes,
  }) async {
    try {
      final response = await _api.dio.post('/material/out', data: {
        'siteId': siteId,
        'itemId': itemId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<Map<String, dynamic>> materialReturn({
    required String siteId,
    required String itemId,
    required int quantity,
    required String state, // BON | DEGRADE | MANQUANT
    String? retentionTarget, // ONE_AGENT | WHOLE_GROUP
    String? agentId,
    String? notes,
  }) async {
    try {
      final response = await _api.dio.post('/material/return', data: {
        'siteId': siteId,
        'itemId': itemId,
        'quantity': quantity,
        'state': state,
        if (retentionTarget != null) 'retentionTarget': retentionTarget,
        if (agentId != null) 'agentId': agentId,
        if (notes != null) 'notes': notes,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> getBySite(String siteId) async {
    try {
      final response = await _api.dio.get('/material/site/$siteId');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> getVehicleAlerts() async {
    try {
      final response = await _api.dio.get('/material/vehicle-alerts');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
