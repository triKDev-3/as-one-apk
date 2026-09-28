import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class SiteChefInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;

  SiteChefInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory SiteChefInfo.fromJson(Map<String, dynamic> json) {
    final chef = json['chef'] as Map<String, dynamic>? ?? json;
    return SiteChefInfo(
      id: (chef['id'] ?? json['chefId']) as String? ?? '',
      firstName: chef['firstName'] as String? ?? '',
      lastName: chef['lastName'] as String? ?? '',
      phone: chef['phone'] as String?,
    );
  }
}

class SiteActiveAssignment {
  final String id;
  final String status;
  final String agentName;
  final String agentId;
  final String? startDate;
  final String? endDate;

  SiteActiveAssignment({
    required this.id,
    required this.status,
    required this.agentName,
    required this.agentId,
    this.startDate,
    this.endDate,
  });

  factory SiteActiveAssignment.fromJson(Map<String, dynamic> json) {
    return SiteActiveAssignment(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      agentName: json['agentName'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );
  }
}

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
  final List<SiteChefInfo> chefs;
  final int activeAgentsCount;
  final List<SiteActiveAssignment> activeAssignments;
  final double? dailyRate;
  final double? nightRate;
  final double? sundayRate;
  final double? bonusAmount;
  final double? monthlySalary;
  final double? fixedAmount;
  /// false si des actions ont déjà été menées (pointages, affectations…)
  final bool canDelete;

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
    this.chefs = const [],
    this.activeAgentsCount = 0,
    this.activeAssignments = const [],
    this.dailyRate,
    this.nightRate,
    this.sundayRate,
    this.bonusAmount,
    this.monthlySalary,
    this.fixedAmount,
    this.canDelete = true,
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final chefsRaw = (json['chefs'] as List<dynamic>?) ?? [];
    final chefs = chefsRaw
        .map((c) => SiteChefInfo.fromJson(c as Map<String, dynamic>))
        .where((c) => c.id.isNotEmpty)
        .toList();

    final activeRaw = (json['activeAssignments'] as List<dynamic>?) ?? [];
    final active = activeRaw
        .map((a) => SiteActiveAssignment.fromJson(a as Map<String, dynamic>))
        .toList();

    return SiteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'CHANTIER',
      address: json['address'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      chefIds: chefs.map((c) => c.id).toList(),
      chefs: chefs,
      activeAgentsCount:
          (json['activeAgentsCount'] as num?)?.toInt() ?? active.length,
      activeAssignments: active,
      dailyRate: toDouble(json['dailyRate']),
      nightRate: toDouble(json['nightRate']),
      sundayRate: toDouble(json['sundayRate']),
      bonusAmount: toDouble(json['bonusAmount']),
      monthlySalary: toDouble(json['monthlySalary']),
      fixedAmount: toDouble(json['fixedAmount']),
      canDelete: json['canDelete'] as bool? ?? true,
    );
  }

  bool get isPermanence => type == 'PERMANENCE';
  bool get isChantier => type == 'CHANTIER';
  bool get isRoutine => type == 'ROUTINE';
  bool get hasChefs => chefs.isNotEmpty;
  bool get hasOperations => activeAgentsCount > 0;

  String get chefsLabel {
    if (chefs.isEmpty) return 'Aucun chef assigné';
    if (chefs.length == 1) return chefs.first.fullName;
    return '${chefs.length} chefs : ${chefs.map((c) => c.fullName).join(', ')}';
  }

  String get typeLabel {
    switch (type) {
      case 'PERMANENCE':
        return 'Permanence';
      case 'ROUTINE':
        return 'Routine';
      default:
        return 'Chantier';
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

  Future<SiteModel> createSite(Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.post('/sites', data: data);
      return SiteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<SiteModel> updateSite(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.patch('/sites/$id', data: data);
      return SiteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> deleteSite(String id) async {
    try {
      await _api.dio.delete('/sites/$id');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> assignChef(String siteId, String chefId) async {
    try {
      await _api.dio.post('/sites/$siteId/chefs/$chefId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> removeChef(String siteId, String chefId) async {
    try {
      await _api.dio.delete('/sites/$siteId/chefs/$chefId');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
