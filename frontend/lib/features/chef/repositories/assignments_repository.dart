import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AssignmentModel {
  final String id;
  final String siteId;
  final String agentId;
  final String status;
  final bool isLocked;
  final String? startDate;
  final String? endDate;
  final Map<String, dynamic>? agent;
  final Map<String, dynamic>? site;

  AssignmentModel({
    required this.id,
    required this.siteId,
    required this.agentId,
    required this.status,
    this.isLocked = false,
    this.startDate,
    this.endDate,
    this.agent,
    this.site,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      siteId: json['siteId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      isLocked: json['isLocked'] as bool? ?? false,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      agent: json['agent'] as Map<String, dynamic>?,
      site: json['site'] as Map<String, dynamic>?,
    );
  }

  String get agentName {
    if (agent == null) return 'Agent';
    return '${agent!['firstName'] ?? ''} ${agent!['lastName'] ?? ''}'.trim();
  }

  String get agentPhone => agent?['phone'] as String? ?? '';

  List<String> get unavailableDates {
    final profile = agent?['agentProfile'] as Map<String, dynamic>?;
    final raw = profile?['unavailableDates'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  bool isUnavailableOn(String yyyyMmDd) => unavailableDates.contains(yyyyMmDd);
}

class LockedSiteInfo {
  final String siteId;
  final String siteName;
  final String status;

  LockedSiteInfo({
    required this.siteId,
    required this.siteName,
    required this.status,
  });

  factory LockedSiteInfo.fromJson(Map<String, dynamic> json) {
    return LockedSiteInfo(
      siteId: json['siteId'] as String? ?? '',
      siteName: json['siteName'] as String? ?? 'Autre site',
      status: json['status'] as String? ?? '',
    );
  }
}

class AvailableAgent {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String contractType;
  final double rankingScore;
  final double? avgScore;
  final int daysWorked;
  final bool isAvailable;
  final bool isLockedElsewhere;
  final bool canForceMultiSite;
  final List<LockedSiteInfo> lockedOnSites;
  final List<String> unavailableDates;
  final bool isUnavailableToday;

  AvailableAgent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.contractType = 'TEMPORAIRE',
    this.rankingScore = 0,
    this.avgScore,
    this.daysWorked = 0,
    this.isAvailable = true,
    this.isLockedElsewhere = false,
    this.canForceMultiSite = false,
    this.lockedOnSites = const [],
    this.unavailableDates = const [],
    this.isUnavailableToday = false,
  });

  String get fullName => '$firstName $lastName';

  String get lockedSitesLabel =>
      lockedOnSites.map((s) => s.siteName).join(', ');

  bool isUnavailableOn(String yyyyMmDd) => unavailableDates.contains(yyyyMmDd);

  factory AvailableAgent.fromJson(Map<String, dynamic> json) {
    final rawDates = json['unavailableDates'];
    final dates = rawDates is List
        ? rawDates.map((e) => e.toString()).toList()
        : <String>[];
    final rawLocked = json['lockedOnSites'];
    final locked = rawLocked is List
        ? rawLocked
            .map((e) => LockedSiteInfo.fromJson(e as Map<String, dynamic>))
            .toList()
        : <LockedSiteInfo>[];
    return AvailableAgent(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      contractType: json['contractType'] as String? ?? 'TEMPORAIRE',
      rankingScore: (json['rankingScore'] as num?)?.toDouble() ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble(),
      daysWorked: (json['daysWorked'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isLockedElsewhere: json['isLockedElsewhere'] as bool? ?? false,
      canForceMultiSite: json['canForceMultiSite'] as bool? ?? false,
      lockedOnSites: locked,
      unavailableDates: dates,
      isUnavailableToday: json['isUnavailableToday'] as bool? ?? false,
    );
  }
}

class AssignmentsRepository {
  final ApiClient _api;

  AssignmentsRepository(this._api);

  Future<List<AvailableAgent>> getAvailableAgents({String? siteId}) async {
    try {
      final response = await _api.dio.get(
        '/assignments/agents/available',
        queryParameters: siteId != null ? {'siteId': siteId} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AvailableAgent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<AssignmentModel>> getBySite(String siteId) async {
    try {
      final response = await _api.dio.get('/assignments/site/$siteId');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<AssignmentModel> createAssignment({
    required String siteId,
    required String agentId,
    required String startDate,
    String? endDate,
    String? missionType,
    List<int>? routineDays,
    double? fixedSalary,
    bool forceMultiSite = false,
  }) async {
    try {
      final data = {
        'siteId': siteId,
        'agentId': agentId,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (missionType != null) 'missionType': missionType,
        if (routineDays != null) 'routineDays': routineDays,
        if (fixedSalary != null) 'fixedSalary': fixedSalary,
        if (forceMultiSite) 'forceMultiSite': true,
      };
      final response = await _api.dio.post('/assignments', data: data);
      return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> requestTransfer({
    required String assignmentId,
    required String toChefId,
  }) async {
    try {
      await _api.dio.post(
        '/assignments/$assignmentId/transfer',
        data: {'toChefId': toChefId},
      );
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> listChefs() async {
    try {
      final response = await _api.dio.get('/assignments/chefs');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> releaseAgent(String assignmentId) async {
    try {
      await _api.dio.patch('/assignments/$assignmentId/release');
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
