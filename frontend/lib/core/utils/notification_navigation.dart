import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// Mappe type + data d'une notification vers l'écran métier concerné.
class NotificationNavigation {
  static String Function()? _roleGetter;

  /// À appeler une fois l'utilisateur connu (RoleShell / après login).
  static void setRoleGetter(String Function() getter) {
    _roleGetter = getter;
  }

  static String get _role => _roleGetter?.call() ?? 'AGENT';

  /// Retourne un path go_router, ou null si inconnu.
  static String? resolvePath({
    required String type,
    required String role,
    Map<String, dynamic>? data,
  }) {
    final t = type.toLowerCase();
    final siteId = data?['siteId']?.toString();
    final base = _roleBase(role);

    // Affectations → agent
    if (t.contains('assignment:new') ||
        (t.contains('assignment') &&
            !t.contains('response') &&
            !t.contains('multi') &&
            role == 'AGENT')) {
      return '/agent';
    }

    // Réponse agent / multi-sites → chef composition
    if (t.contains('assignment:response') ||
        t.contains('assignment:multi_site')) {
      if (role == 'CHEF' || role == 'ADMIN') {
        if (siteId != null && siteId.isNotEmpty) return '/chef/compose/$siteId';
        return role == 'ADMIN' ? '/admin' : '/chef';
      }
    }

    // Transferts d'agents
    if (t.contains('transfer') && !t.contains('site')) {
      if (role == 'CHEF') return '/chef/transfers';
      if (role == 'ADMIN') return '/admin';
    }

    // Site confié entre chefs
    if (t.contains('site_transfer') ||
        t.contains('site-transfer') ||
        t == 'site_transfer') {
      if (role == 'CHEF') {
        if (siteId != null && siteId.isNotEmpty) return '/chef/site/$siteId';
        return '/chef/select-site';
      }
    }

    // Pointages
    if (t.contains('pointage')) {
      if (role == 'CHEF') {
        if (siteId != null && siteId.isNotEmpty) {
          return '/chef/pointage/$siteId';
        }
        return '/chef/pointages';
      }
      if (role == 'AGENT') return '/agent/pointages';
      if (role == 'ADMIN') return '/admin/pointages';
      if (role == 'COMPTABLE') return '/comptable/pointages';
      if (role == 'MAGASINIER') return '/magasinier/pointages';
    }

    // Incidents / pénalités
    if (t.contains('incident') || t.contains('penalty')) {
      if (role == 'CHEF') return '/chef/incidents';
      if (role == 'ADMIN') return '/admin/incidents';
      if (role == 'MAGASINIER') return '/magasinier/incidents';
      if (role == 'COMPTABLE') return '/comptable/incidents';
      return '$base/notifications';
    }

    // Offres permanence
    if (t.contains('offer') || t.contains('permanence')) {
      if (role == 'AGENT') return '/agent/offers';
      if (role == 'CHEF' && siteId != null && siteId.isNotEmpty) {
        return '/chef/permanence/$siteId';
      }
      if (role == 'CHEF') return '/chef';
    }

    // Paie
    if (t.contains('payroll') || t.contains('paie')) {
      if (role == 'COMPTABLE') return '/comptable';
      if (role == 'AGENT') return '/agent/remuneration';
      if (role == 'ADMIN') return '/admin';
    }

    // Indisponibilité
    if (t.contains('unavailable') || t.contains('availability')) {
      if (role == 'CHEF') return '/chef';
      if (role == 'AGENT') return '/agent/planning';
    }

    return '$base/notifications';
  }

  static String _roleBase(String role) {
    switch (role.toUpperCase()) {
      case 'AGENT':
        return '/agent';
      case 'CHEF':
        return '/chef';
      case 'ADMIN':
        return '/admin';
      case 'MAGASINIER':
        return '/magasinier';
      case 'COMPTABLE':
        return '/comptable';
      default:
        return '/agent';
    }
  }

  static void open(
    BuildContext context, {
    required String type,
    required String role,
    Map<String, dynamic>? data,
  }) {
    final path = resolvePath(type: type, role: role, data: data);
    if (path == null || path.isEmpty) return;
    try {
      context.push(path);
    } catch (_) {
      try {
        context.go(path);
      } catch (_) {}
    }
  }

  static void handleData({
    required String type,
    Map<String, dynamic>? data,
  }) {
    final path = resolvePath(type: type, role: _role, data: data);
    if (path == null || path.isEmpty) return;
    try {
      AppRouter.router.push(path);
    } catch (_) {
      try {
        AppRouter.router.go(path);
      } catch (_) {}
    }
  }

  static void handlePayload(String? payload) {
    final decoded = decodePayload(payload);
    handleData(
      type: decoded['type'] as String? ?? '',
      data: decoded['data'] as Map<String, dynamic>?,
    );
  }

  static String encodePayload({
    required String type,
    Map<String, dynamic>? data,
  }) {
    final siteId = data?['siteId']?.toString() ?? '';
    final assignmentId =
        data?['assignmentId']?.toString() ?? data?['id']?.toString() ?? '';
    return '$type|$siteId|$assignmentId';
  }

  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return {'type': '', 'data': <String, dynamic>{}};
    }
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final siteId = parts.length > 1 ? parts[1] : '';
    final assignmentId = parts.length > 2 ? parts[2] : '';
    final data = <String, dynamic>{};
    if (siteId.isNotEmpty) data['siteId'] = siteId;
    if (assignmentId.isNotEmpty) {
      data['assignmentId'] = assignmentId;
      data['id'] = assignmentId;
    }
    return {'type': type, 'data': data};
  }
}
