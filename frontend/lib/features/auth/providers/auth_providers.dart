import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// Current user state
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// Auth token state
final authTokenProvider = StateProvider<String?>((ref) => null);

// User role
final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

// Is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authTokenProvider) != null && ref.watch(currentUserProvider) != null;
});

// Login mutation
final loginProvider = FutureProvider.family<void, ({String phone, String password})>((ref, credentials) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    final response = await api.login(credentials.phone, credentials.password);
    
    ref.read(authTokenProvider.notifier).state = response['token'];
    ref.read(currentUserProvider.notifier).state = UserModel.fromJson(response['user']);
  } catch (e) {
    rethrow;
  }
});

// Logout
final logoutProvider = Provider((ref) {
  return () {
    ref.read(authTokenProvider.notifier).state = null;
    ref.read(currentUserProvider.notifier).state = null;
  };
});
