import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/pointage_model.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// List of pointages for current assignment
final pointagesForAssignmentProvider =
    FutureProvider.family<List<PointageModel>, String>((ref, assignmentId) async {
  final api = ref.watch(apiClientProvider);
  return api.getPointagesForAssignment(assignmentId);
});

// Today's pointages
final todayPointagesProvider = FutureProvider<List<PointageModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getTodayPointages();
});

// Pointage form state (for optimistic updates)
final pointageFormProvider = StateNotifierProvider<PointageFormNotifier, PointageFormState>((ref) {
  return PointageFormNotifier();
});

// Loading state
final pointageLoadingProvider = StateProvider<bool>((ref) => false);

// Error state
final pointageErrorProvider = StateProvider<String?>((ref) => null);

// Submit pointage mutation
final submitPointageProvider = FutureProvider.family<PointageModel, PointageFormState>((ref, formState) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    ref.read(pointageLoadingProvider.notifier).state = true;
    ref.read(pointageErrorProvider.notifier).state = null;
    
    final pointage = await api.submitPointage(formState);
    
    // Invalidate related caches
    ref.invalidate(pointagesForAssignmentProvider);
    ref.invalidate(todayPointagesProvider);
    ref.invalidate(pointageFormProvider);
    
    return pointage;
  } catch (e) {
    ref.read(pointageErrorProvider.notifier).state = e.toString();
    rethrow;
  } finally {
    ref.read(pointageLoadingProvider.notifier).state = false;
  }
});

// Form state model
class PointageFormState {
  final String? assignmentId;
  final String? siteId;
  final String? photoBase64;
  final double? latitude;
  final double? longitude;
  final String type;

  PointageFormState({
    this.assignmentId,
    this.siteId,
    this.photoBase64,
    this.latitude,
    this.longitude,
    this.type = 'ARRIVEE',
  });

  PointageFormState copyWith({
    String? assignmentId,
    String? siteId,
    String? photoBase64,
    double? latitude,
    double? longitude,
    String? type,
  }) {
    return PointageFormState(
      assignmentId: assignmentId ?? this.assignmentId,
      siteId: siteId ?? this.siteId,
      photoBase64: photoBase64 ?? this.photoBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
    );
  }
}

// Form notifier for optimistic updates
class PointageFormNotifier extends StateNotifier<PointageFormState> {
  PointageFormNotifier() : super(PointageFormState());

  void updateAssignmentId(String id) {
    state = state.copyWith(assignmentId: id);
  }

  void updateSiteId(String id) {
    state = state.copyWith(siteId: id);
  }

  void updatePhoto(String base64) {
    state = state.copyWith(photoBase64: base64);
  }

  void updateLocation(double lat, double lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
  }

  void updateType(String type) {
    state = state.copyWith(type: type);
  }

  void reset() {
    state = PointageFormState();
  }
}
