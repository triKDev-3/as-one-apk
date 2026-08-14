import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Génère le texte métier et ouvre WhatsApp / SMS / copie.
class WhatsAppHelper {
  /// Message standard d'affectation
  static String assignmentMessage({
    required String agentName,
    required String siteName,
    required String startDate,
    String? endDate,
    String? chefName,
  }) {
    final period = endDate != null && endDate.isNotEmpty
        ? 'du $startDate au $endDate'
        : 'le $startDate';

    return '''Bonjour $agentName,

Vous êtes affecté(e) sur le site :
📍 $siteName
📅 $period

Merci de confirmer votre disponibilité dans l'application AS ONE avant 22h.

${chefName != null ? '— $chefName' : '— AS ONE Facility Management'}''';
  }

  /// Rapport de fin de chantier (texte WhatsApp)
  static String siteReportMessage(Map<String, dynamic> report) {
    final details = report['details'] as Map<String, dynamic>? ?? {};
    final site = details['site'] as Map<String, dynamic>? ?? {};
    final period = details['period'] as Map<String, dynamic>? ?? {};
    final tasks = details['tasks'] as List<dynamic>? ?? [];
    final team = details['team'] as List<dynamic>? ?? [];
    final stats = details['stats'] as Map<String, dynamic>? ?? {};
    final summary = report['summary'] as String?;
    final chef = report['createdBy'] as Map<String, dynamic>?;

    String fmt(dynamic d) {
      if (d == null) return '—';
      final s = d.toString();
      if (s.length >= 10) {
        // ISO → JJ/MM/AAAA
        try {
          final dt = DateTime.parse(s);
          final dd = dt.day.toString().padLeft(2, '0');
          final mm = dt.month.toString().padLeft(2, '0');
          return '$dd/$mm/${dt.year}';
        } catch (_) {
          return s.substring(0, 10);
        }
      }
      return s;
    }

    final siteName = site['name']?.toString() ?? 'Chantier';
    final siteType = site['type']?.toString() ?? '';
    final address = site['address']?.toString() ?? '';
    final start = fmt(period['startDate'] ?? report['startDate']);
    final end = fmt(period['endDate'] ?? report['endDate']);

    final buf = StringBuffer();
    buf.writeln('📋 *RAPPORT FIN DE CHANTIER — AS ONE*');
    buf.writeln('');
    buf.writeln('📍 *Site :* $siteName');
    if (siteType.isNotEmpty) buf.writeln('🏷️ *Type :* $siteType');
    if (address.isNotEmpty) buf.writeln('📌 *Adresse :* $address');
    buf.writeln('📅 *Période :* $start → $end');
    buf.writeln('');
    buf.writeln('📊 *Bilan*');
    buf.writeln('• Tâches : ${stats['tasksCount'] ?? tasks.length}');
    buf.writeln('• Équipe : ${stats['teamSize'] ?? team.length} agent(s)');
    buf.writeln('• Pointages : ${stats['pointagesCount'] ?? 0}');
    buf.writeln('• Matériel : ${stats['materialsCount'] ?? 0} mouvement(s)');
    buf.writeln('• Incidents : ${stats['incidentsCount'] ?? 0}');

    if (team.isNotEmpty) {
      buf.writeln('');
      buf.writeln('👥 *Équipe*');
      for (final a in team.take(15)) {
        final m = a as Map<String, dynamic>;
        final agent = m['agent'] as Map<String, dynamic>? ?? {};
        final name =
            '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'.trim();
        if (name.isNotEmpty) buf.writeln('• $name');
      }
      if (team.length > 15) {
        buf.writeln('• … +${team.length - 15} autres');
      }
    }

    if (tasks.isNotEmpty) {
      buf.writeln('');
      buf.writeln('✅ *Tâches réalisées*');
      for (final t in tasks.take(20)) {
        final m = t as Map<String, dynamic>;
        final desc = m['description']?.toString() ?? '';
        final when = fmt(m['performedAt']);
        buf.writeln('• [$when] $desc');
      }
      if (tasks.length > 20) {
        buf.writeln('• … +${tasks.length - 20} autres tâches');
      }
    }

    if (summary != null && summary.trim().isNotEmpty) {
      buf.writeln('');
      buf.writeln('📝 *Résumé du chef*');
      buf.writeln(summary.trim());
    }

    buf.writeln('');
    if (chef != null) {
      final cn =
          '${chef['firstName'] ?? ''} ${chef['lastName'] ?? ''}'.trim();
      if (cn.isNotEmpty) buf.writeln('— Chef : $cn');
    }
    buf.writeln('— AS ONE Facility Management');

    return buf.toString();
  }

  /// Nettoie le numéro pour wa.me
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');
  }

  /// Ouvre WhatsApp (avec ou sans numéro — si vide, choix du contact)
  static Future<bool> openWhatsApp({
    String phone = '',
    required String message,
  }) async {
    final cleaned = phone.isEmpty ? '' : cleanPhone(phone);
    final uri = cleaned.isEmpty
        ? Uri.parse(
            'https://wa.me/?text=${Uri.encodeComponent(message)}',
          )
        : Uri.parse(
            'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}',
          );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> openSms({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse(
      'sms:$phone?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  static Future<void> copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
  }
}
