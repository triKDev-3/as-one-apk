import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum OpsHistoryFilter { all, pointage, incident, task, agent }

String opsKindLabelFr(String kind) {
  switch (kind) {
    case 'assignment':
      return 'Assigné';
    case 'assignment_pending':
      return 'En attente';
    case 'pointage':
      return 'Pointé';
    case 'absent':
      return 'Absent';
    case 'incident':
      return 'Incident';
    case 'task':
      return 'Tâche';
    default:
      return kind;
  }
}

bool opsHistoryMatches(String kind, OpsHistoryFilter filter) {
  switch (filter) {
    case OpsHistoryFilter.all:
      return true;
    case OpsHistoryFilter.pointage:
      return kind == 'pointage' || kind == 'absent';
    case OpsHistoryFilter.incident:
      return kind == 'incident';
    case OpsHistoryFilter.task:
      return kind == 'task';
    case OpsHistoryFilter.agent:
      return kind == 'assignment' || kind == 'assignment_pending';
  }
}

String opsHistoryEmptyLabel(OpsHistoryFilter filter) {
  switch (filter) {
    case OpsHistoryFilter.all:
      return 'Aucune opération pour ce jour';
    case OpsHistoryFilter.pointage:
      return 'Aucun pointage pour ce jour';
    case OpsHistoryFilter.incident:
      return 'Aucun incident pour ce jour';
    case OpsHistoryFilter.task:
      return 'Aucune tâche pour ce jour';
    case OpsHistoryFilter.agent:
      return 'Aucune affectation pour ce jour';
  }
}

class OpsHistoryFilterBar extends StatelessWidget {
  final OpsHistoryFilter value;
  final ValueChanged<OpsHistoryFilter> onChanged;

  const OpsHistoryFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (OpsHistoryFilter.all, 'Toutes', Icons.layers_rounded),
      (OpsHistoryFilter.pointage, 'Pointages', Icons.fingerprint),
      (OpsHistoryFilter.incident, 'Incidents', Icons.warning_amber_rounded),
      (OpsHistoryFilter.task, 'Tâches', Icons.task_alt_rounded),
      (OpsHistoryFilter.agent, 'Agents', Icons.groups_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  item.$3,
                  size: 16,
                  color: value == item.$1
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
                label: Text(item.$2),
                selected: value == item.$1,
                onSelected: (_) => onChanged(item.$1),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: value == item.$1
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: value == item.$1
                      ? AppColors.primary
                      : AppColors.border,
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
