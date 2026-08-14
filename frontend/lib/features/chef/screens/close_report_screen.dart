import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../repositories/sites_repository.dart';
import 'select_site_screen.dart';

class CloseReportScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const CloseReportScreen({super.key, required this.siteId, this.site});

  @override
  ConsumerState<CloseReportScreen> createState() => _CloseReportScreenState();
}

class _CloseReportScreenState extends ConsumerState<CloseReportScreen> {
  final _summaryCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _loading = false;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _start = widget.site?.startDate != null
        ? DateTime.tryParse(widget.site!.startDate!)
        : null;
    _end = DateTime.now();
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? DateTime.now(),
      firstDate: _start ?? DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _end = d);
  }

  Future<void> _submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer le chantier ?'),
        content: const Text(
          'Un rapport définitif sera généré (tâches, équipe, pointages, matériel, incidents). Le site sera marqué comme terminé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/sites/${widget.siteId}/close-report',
        data: {
          if (_summaryCtrl.text.trim().isNotEmpty)
            'summary': _summaryCtrl.text.trim(),
          if (_start != null)
            'startDate': DateFormat('yyyy-MM-dd').format(_start!),
          if (_end != null) 'endDate': DateFormat('yyyy-MM-dd').format(_end!),
        },
      );
      final reportData = response.data as Map<String, dynamic>;
      setState(() => _report = reportData);
      ref.invalidate(sitesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport généré — envoi WhatsApp…'),
            backgroundColor: AppColors.accent,
          ),
        );
        // Propose l'envoi WhatsApp immédiatement
        final msg = WhatsAppHelper.siteReportMessage(reportData);
        await WhatsAppHelper.openWhatsApp(message: msg);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Chantier';

    if (_report != null) {
      return _ReportView(report: _report!, siteName: siteName);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Rapport — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Fin de chantier',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Le rapport inclura automatiquement : dates, tâches datées, équipe, pointages, matériel et incidents.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date début'),
                  subtitle: Text(
                    _start != null
                        ? DateFormat('dd/MM/yyyy').format(_start!)
                        : '—',
                  ),
                  onTap: _pickStart,
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date fin'),
                  subtitle: Text(
                    _end != null
                        ? DateFormat('dd/MM/yyyy').format(_end!)
                        : '—',
                  ),
                  onTap: _pickEnd,
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Résumé du chef (optionnel)',
              alignLabelWithHint: true,
              hintText: 'Travaux réalisés, observations, recommandations…',
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.assignment_turned_in),
            label: const Text('Générer le rapport final'),
          ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  final String siteName;

  const _ReportView({required this.report, required this.siteName});

  @override
  Widget build(BuildContext context) {
    final details = report['details'] as Map<String, dynamic>? ?? {};
    final period = details['period'] as Map<String, dynamic>? ?? {};
    final tasks = details['tasks'] as List<dynamic>? ?? [];
    final team = details['team'] as List<dynamic>? ?? [];
    final stats = details['stats'] as Map<String, dynamic>? ?? {};
    final site = details['site'] as Map<String, dynamic>? ?? {};
    final summary = report['summary'] as String?;

    String fmt(dynamic d) {
      if (d == null) return '—';
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(d.toString()));
      } catch (_) {
        return d.toString().length >= 10
            ? d.toString().substring(0, 10)
            : d.toString();
      }
    }

    final message = WhatsAppHelper.siteReportMessage(report);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rapport final'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chef'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            site['name']?.toString() ?? siteName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${site['type'] ?? ''} · ${site['address'] ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Période',
            value: '${fmt(period['startDate'])} → ${fmt(period['endDate'])}',
          ),
          _InfoRow(
            label: 'Tâches',
            value: '${stats['tasksCount'] ?? tasks.length}',
          ),
          _InfoRow(
            label: 'Équipe',
            value: '${stats['teamSize'] ?? team.length} agent(s)',
          ),
          _InfoRow(
            label: 'Pointages',
            value: '${stats['pointagesCount'] ?? 0}',
          ),
          _InfoRow(
            label: 'Matériel',
            value: '${stats['materialsCount'] ?? 0} mouvement(s)',
          ),
          _InfoRow(
            label: 'Incidents',
            value: '${stats['incidentsCount'] ?? 0}',
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Résumé', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(summary),
          ],
          const SizedBox(height: 20),
          Text(
            'Historique des tâches',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Text('Aucune tâche')
          else
            ...tasks.map((t) {
              final m = t as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: AppColors.accent),
                title: Text(m['description']?.toString() ?? ''),
                subtitle: Text(
                  '${fmt(m['performedAt'])}${m['by'] != null ? ' · ${m['by']}' : ''}',
                ),
              );
            }),
          const SizedBox(height: 16),
          Text('Équipe', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...team.map((a) {
            final m = a as Map<String, dynamic>;
            final agent = m['agent'] as Map<String, dynamic>? ?? {};
            final name =
                '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'.trim();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name.isEmpty ? 'Agent' : name),
              subtitle: Text('${agent['phone'] ?? ''} · ${m['status'] ?? ''}'),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await WhatsAppHelper.copyMessage(message);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rapport copié')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await WhatsAppHelper.openWhatsApp(
                      message: message,
                    );
                    if (!ok && context.mounted) {
                      await WhatsAppHelper.copyMessage(message);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'WhatsApp indisponible — texte copié',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('Envoyer WhatsApp'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
