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
  final List<String> chefIds;
  final double? dailyRate;
  final double? nightRate;
  final double? sundayRate;
  final double? bonusAmount;
  final double? monthlySalary;
  final double? fixedAmount;

  SiteModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.location,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.chefIds = const [],
    this.dailyRate,
    this.nightRate,
    this.sundayRate,
    this.bonusAmount,
    this.monthlySalary,
    this.fixedAmount,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return SiteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'CHANTIER',
      address: json['address'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      chefIds: (json['chefs'] as List<dynamic>?)
              ?.map((c) => c['chefId'] as String)
              .toList() ??
          [],
      dailyRate: toDouble(json['dailyRate']),
      nightRate: toDouble(json['nightRate']),
      sundayRate: toDouble(json['sundayRate']),
      bonusAmount: toDouble(json['bonusAmount']),
      monthlySalary: toDouble(json['monthlySalary']),
      fixedAmount: toDouble(json['fixedAmount']),
    );
  }

  bool get isPermanence => type == 'PERMANENCE';
  bool get isChantier => type == 'CHANTIER';
  bool get isRoutine => type == 'ROUTINE';

  String get typeLabel {
    switch (type) {
      case 'PERMANENCE': return 'Permanence';
      case 'ROUTINE': return 'Routine';
      default: return 'Chantier';
    }
  }
}

class SitesRepository {
  final ApiClient _api;

  SitesRepository(this._api);

  Future<List<SiteModel>> getSites({String? type, bool all = false}) async {
    try {
      final query = <String, dynamic>{
        if (type != null) 'type': type,
        if (all) 'all': 'true',
      };
      
      final response = await _api.dio.get(
        '/sites',
        queryParameters: query.isNotEmpty ? query : null,
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
