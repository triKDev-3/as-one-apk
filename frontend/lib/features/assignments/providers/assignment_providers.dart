import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/assignment_model.dart';

// API Client provider
final apiClientProvider = Provider((ref) => ApiClient());

// Single assignment query
final assignmentProvider =
    FutureProvider.family<AssignmentModel, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  return api.getAssignment(id);
});

// List of assignments for current user
final myAssignmentsProvider = FutureProvider<List<AssignmentModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getMyAssignments();
});

// Filtered assignments by status
final assignmentsByStatusProvider = FutureProvider.family<List<AssignmentModel>, String>((ref, status) async {
  final api = ref.watch(apiClientProvider);
  return api.getAssignmentsByStatus(status);
});

// Loading state for assignment operations
final assignmentLoadingProvider = StateProvider<bool>((ref) => false);

// Error state for assignment operations
final assignmentErrorProvider = StateProvider<String?>((ref) => null);

// Confirm assignment mutation
final confirmAssignmentProvider = FutureProvider.family<void, String>((ref, assignmentId) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    ref.read(assignmentLoadingProvider.notifier).state = true;
    ref.read(assignmentErrorProvider.notifier).state = null;
    
    await api.confirmAssignment(assignmentId);
    
    // Invalidate cached data after successful operation
    ref.invalidate(myAssignmentsProvider);
    ref.invalidate(assignmentProvider);
    ref.invalidate(assignmentsByStatusProvider);
  } catch (e) {
    ref.read(assignmentErrorProvider.notifier).state = e.toString();
    rethrow;
  } finally {
    ref.read(assignmentLoadingProvider.notifier).state = false;
  }
});

// Refuse assignment mutation
final refuseAssignmentProvider = FutureProvider.family<void, String>((ref, assignmentId) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    ref.read(assignmentLoadingProvider.notifier).state = true;
    ref.read(assignmentErrorProvider.notifier).state = null;
    
    await api.refuseAssignment(assignmentId);
    
    ref.invalidate(myAssignmentsProvider);
    ref.invalidate(assignmentProvider);
  } catch (e) {
    ref.read(assignmentErrorProvider.notifier).state = e.toString();
    rethrow;
  } finally {
    ref.read(assignmentLoadingProvider.notifier).state = false;
  }
});

// Transfer assignment mutation
final transferAssignmentProvider = FutureProvider.family<void, ({String assignmentId, String toChefId})>((ref, params) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    ref.read(assignmentLoadingProvider.notifier).state = true;
    ref.read(assignmentErrorProvider.notifier).state = null;
    
    await api.transferAssignment(params.assignmentId, params.toChefId);
    
    ref.invalidate(myAssignmentsProvider);
  } catch (e) {
    ref.read(assignmentErrorProvider.notifier).state = e.toString();
    rethrow;
  } finally {
    ref.read(assignmentLoadingProvider.notifier).state = false;
  }
});
