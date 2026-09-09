import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../services/share_service.dart';
import '../widgets/admin_checklist_editor.dart';
import '../widgets/admin_segmented_switcher.dart';

class AdminFiveSScreen extends StatelessWidget {
  const AdminFiveSScreen({required this.onNavigate, this.onShare, super.key});

  final AdminNavigationCallback onNavigate;
  final ShareTextCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AdminChecklistEditor(
      module: AdminDestination.fiveS,
      onNavigate: onNavigate,
      onShare: onShare,
      topContent: AdminChecklistSwitcher(
        activeModule: AdminDestination.fiveS,
        onChanged: onNavigate,
      ),
      eyebrow: 'Daily compliance audit',
      title: 'Gateway 5S Checklist',
      description:
          'Complete the daily Sales and Service 5S audit or edit the General '
          "Manager's master checklist preset.",
      presetName: 'Gateway Sales & Service 5S',
      presetCount: 56,
      coverageCount: 9,
      initialTemplate: fiveSTemplate,
    );
  }
}
