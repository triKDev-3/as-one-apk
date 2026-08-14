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
}

class AvailableAgent {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? agentType;
  final double rankingScore;
  final bool isAvailable;

  AvailableAgent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.agentType,
    this.rankingScore = 0,
    this.isAvailable = true,
  });

  String get fullName => '$firstName $lastName';

  factory AvailableAgent.fromJson(Map<String, dynamic> json) {
    final profile = json['agentProfile'] as Map<String, dynamic>?;
    return AvailableAgent(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      agentType: json['agentType'] as String?,
      rankingScore: (json['rankingScore'] as num?)?.toDouble() ?? 0,
      isAvailable: profile?['isAvailable'] as bool? ?? true,
    );
  }
}

class AssignmentsRepository {
  final ApiClient _api;

  AssignmentsRepository(this._api);

  Future<List<AvailableAgent>> getAvailableAgents() async {
    try {
      final response = await _api.dio.get('/agent/available');
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
  }) async {
    try {
      final data = {
        'siteId': siteId,
        'agentId': agentId,
        'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
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
}
