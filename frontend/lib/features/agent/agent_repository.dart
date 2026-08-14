import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AgentDashboard {
  final Map<String, dynamic> profile;
  final List<dynamic> assignments;
  final List<dynamic> recentPayroll;
  final List<dynamic> ranking;

  AgentDashboard({
    required this.profile,
    required this.assignments,
    required this.recentPayroll,
    required this.ranking,
  });

  factory AgentDashboard.fromJson(Map<String, dynamic> json) {
    return AgentDashboard(
      profile: json['profile'] as Map<String, dynamic>? ?? {},
      assignments: json['assignments'] as List<dynamic>? ?? [],
      recentPayroll: json['recentPayroll'] as List<dynamic>? ?? [],
      ranking: json['ranking'] as List<dynamic>? ?? [],
    );
  }

  bool get isAvailable => profile['isAvailable'] as bool? ?? true;
  String get fullName =>
      '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
  double get rankingScore =>
      (profile['rankingScore'] as num?)?.toDouble() ?? 0;
  int? get myRank => profile['myRank'] as int?;

  List<dynamic> get pendingAssignments => assignments
      .where((a) => a['status'] == 'PENDING_CONFIRMATION')
      .toList();
}

class AgentRepository {
  final ApiClient _api;

  AgentRepository(this._api);

  Future<bool> toggleAvailability(bool isAvailable) async {
    try {
      final response = await _api.dio.patch(
        '/agent/availability',
        data: {'isAvailable': isAvailable},
      );
      return response.data['isAvailable'] as bool;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<AgentDashboard> getDashboard() async {
    try {
      final response = await _api.dio.get('/agent/me');
      return AgentDashboard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<List<dynamic>> getAvailableAgents() async {
    try {
      final response = await _api.dio.get('/agent/available');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  Future<void> respondToAssignment(String assignmentId, bool accept) async {
    try {
      await _api.dio.patch(
        '/assignments/$assignmentId/respond',
        data: {'accept': accept},
      );
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }
}
