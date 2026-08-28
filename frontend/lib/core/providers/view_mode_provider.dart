import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider pour basculer entre "Mes activités" (false) et "Toutes les activités" (true)
final viewAllProvider = StateProvider<bool>((ref) => false);
