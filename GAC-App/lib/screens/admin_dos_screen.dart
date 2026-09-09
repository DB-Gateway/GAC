import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../services/share_service.dart';
import '../widgets/admin_checklist_editor.dart';
import '../widgets/admin_segmented_switcher.dart';

class AdminDosScreen extends StatelessWidget {
  const AdminDosScreen({required this.onNavigate, this.onShare, super.key});

  final AdminNavigationCallback onNavigate;
  final ShareTextCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return AdminChecklistEditor(
      module: AdminDestination.dos,
      onNavigate: onNavigate,
      onShare: onShare,
      topContent: AdminChecklistSwitcher(
        activeModule: AdminDestination.dos,
        onChanged: onNavigate,
      ),
      eyebrow: 'FY2025 sales compliance audit',
      title: 'Dealer Operations Standards',
      description:
          'Review the Main Form, record findings and corrective actions, or '
          "edit the Sales Manager's master DOS preset.",
      presetName: 'Main Form — FY2025 Sales Standards',
      presetCount: 90,
      coverageCount: 13,
      initialTemplate: dosTemplate,
    );
  }
}
