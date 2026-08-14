import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SiteModel {
  final String id;
  final String name;
  final String type;
  final String? address;
  final String? location;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  SiteModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.location,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'CHANTIER',
      address: json['address'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  bool get isPermanence => type == 'PERMANENCE';
  String get typeLabel => isPermanence ? 'Permanence' : 'Chantier';
}

class SitesRepository {
  final ApiClient _api;

  SitesRepository(this._api);

  Future<List<SiteModel>> getSites({String? type}) async {
    try {
      final response = await _api.dio.get(
        '/sites',
        queryParameters: type != null ? {'type': type} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SiteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<SiteModel> getSite(String id) async {
    try {
      final response = await _api.dio.get('/sites/$id');
      return SiteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
