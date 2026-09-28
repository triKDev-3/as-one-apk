import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../services/push_notification_service.dart';
import '../../features/auth/auth_repository.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/agent/agent_repository.dart';
import '../../features/chef/repositories/sites_repository.dart';
import '../../features/chef/repositories/assignments_repository.dart';
import '../../features/chef/repositories/pointage_repository.dart';
import '../../features/magasinier/repositories/material_repository.dart';
import '../../features/comptable/repositories/payroll_repository.dart';
import '../network/realtime_service.dart';
export 'view_mode_provider.dart';

// ---------- Infrastructure ----------

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(storage);
});

// ---------- Repositories ----------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return AgentRepository(ref.watch(apiClientProvider));
});

// ---------- Auth State ----------

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final RealtimeService _realtime;
  final ApiClient _api;

  AuthNotifier(this._repo, this._realtime, this._api) : super(const AuthState()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    state = state.copyWith(isLoading: true);
    final user = await _repo.getSavedUser();
    if (user != null) {
      _realtime.connect(userId: user.id);
      await PushNotificationService.instance.registerWithBackend(_api);
    }
    state = state.copyWith(
      user: user,
      isLoading: false,
      clearError: true,
    );
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.login(phone: phone, password: password);
      _realtime.connect(userId: user.id);
      await PushNotificationService.instance.registerWithBackend(_api);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await PushNotificationService.instance.unregisterFromBackend(_api);
    _realtime.disconnect();
    await _repo.logout();
    state = const AuthState();
  }

  void updateAvailability(bool isAvailable) {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(isAvailable: isAvailable),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(realtimeServiceProvider),
    ref.watch(apiClientProvider),
  );
});

// ---------- Sites & Assignments (Chef) ----------

final sitesRepositoryProvider = Provider<SitesRepository>((ref) {
  return SitesRepository(ref.watch(apiClientProvider));
});

final assignmentsRepositoryProvider = Provider<AssignmentsRepository>((ref) {
  return AssignmentsRepository(ref.watch(apiClientProvider));
});

final pointageRepositoryProvider = Provider<PointageRepository>((ref) {
  return PointageRepository(ref.watch(apiClientProvider));
});

final availableAgentsProvider =
    FutureProvider.autoDispose.family<List<AvailableAgent>, String?>((ref, siteId) {
  return ref.watch(assignmentsRepositoryProvider).getAvailableAgents(siteId: siteId);
});

final siteAssignmentsProvider = FutureProvider.autoDispose
    .family<List<AssignmentModel>, String>((ref, siteId) {
  return ref.watch(assignmentsRepositoryProvider).getBySite(siteId);
});

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository(ref.watch(apiClientProvider));
});

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(ref.watch(apiClientProvider));
});

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
});
