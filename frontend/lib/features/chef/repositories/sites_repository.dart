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

class SiteHistoryCounts {
  final int assignments;
  final int pointages;
  final int incidents;
  final int tasks;
  final int reports;
  final int material;

  const SiteHistoryCounts({
    this.assignments = 0,
    this.pointages = 0,
    this.incidents = 0,
    this.tasks = 0,
    this.reports = 0,
    this.material = 0,
  });

  factory SiteHistoryCounts.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SiteHistoryCounts();
    return SiteHistoryCounts(
      assignments: (j['assignments'] as num?)?.toInt() ?? 0,
      pointages: (j['pointages'] as num?)?.toInt() ?? 0,
      incidents: (j['incidents'] as num?)?.toInt() ?? 0,
      tasks: (j['tasks'] as num?)?.toInt() ?? 0,
      reports: (j['reports'] as num?)?.toInt() ?? 0,
      material: (j['material'] as num?)?.toInt() ?? 0,
    );
  }

  int get total =>
      assignments + pointages + incidents + tasks + reports + material;
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
  final bool canDelete;
  final bool canRelaunch;
  final SiteHistoryCounts historyCounts;

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
    this.canRelaunch = false,
    this.historyCounts = const SiteHistoryCounts(),
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

    final isActive = json['isActive'] as bool? ?? true;
    final type = json['type'] as String? ?? 'CHANTIER';

    return SiteModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: type,
      address: json['address'] as String?,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      isActive: isActive,
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
      canRelaunch: json['canRelaunch'] as bool? ??
          (!isActive || type == 'PERMANENCE'),
      historyCounts: SiteHistoryCounts.fromJson(
        json['historyCounts'] as Map<String, dynamic>?,
      ),
    );
  }

  bool get isPermanence => type == 'PERMANENCE';
  bool get isChantier => type == 'CHANTIER';
  bool get isRoutine => type == 'ROUTINE';
  bool get isClosed => !isActive;
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

  String get statusLabel => isActive ? 'Actif' : 'Clôturé';
}

class SiteActivityItem {
  final String kind;
  final String title;
  final String? subtitle;
  final String? status;
  final String at;

  SiteActivityItem({
    required this.kind,
    required this.title,
    this.subtitle,
    this.status,
    required this.at,
  });

  factory SiteActivityItem.fromJson(Map<String, dynamic> j) => SiteActivityItem(
        kind: j['kind'] as String? ?? '',
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        status: j['status'] as String?,
        at: j['at'] as String? ?? '',
      );
}

class SiteActivityHistory {
  final SiteModel? site;
  final int total;
  final SiteHistoryCounts counts;
  final List<SiteActivityItem> items;

  SiteActivityHistory({
    this.site,
    required this.total,
    required this.counts,
    required this.items,
  });

  factory SiteActivityHistory.fromJson(Map<String, dynamic> j) {
    final siteJson = j['site'] as Map<String, dynamic>?;
    return SiteActivityHistory(
      site: siteJson != null ? SiteModel.fromJson(siteJson) : null,
      total: (j['total'] as num?)?.toInt() ?? 0,
      counts: SiteHistoryCounts.fromJson(j['counts'] as Map<String, dynamic>?),
      items: ((j['items'] as List<dynamic>?) ?? [])
          .map((e) => SiteActivityItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SitesRepository {
  final ApiClient _api;

  SitesRepository(this._api);

  Future<List<SiteModel>> getSites({
    String? type,
    bool all = false,
    bool includeInactive = false,
  }) async {
    try {
      final query = <String, dynamic>{
        if (type != null) 'type': type,
        if (all) 'all': 'true',
        if (includeInactive) 'includeInactive': 'true',
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

  Future<SiteActivityHistory> getActivityHistory(String id) async {
    try {
      final response = await _api.dio.get('/sites/$id/history');
      return SiteActivityHistory.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<SiteModel> relaunchSite(
    String id, {
    String? reason,
    String? startDate,
  }) async {
    try {
      final response = await _api.dio.post(
        '/sites/$id/relaunch',
        data: {
          if (reason != null) 'reason': reason,
          if (startDate != null) 'startDate': startDate,
        },
      );
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
