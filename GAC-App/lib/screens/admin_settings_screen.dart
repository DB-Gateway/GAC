import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_ui.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({required this.onNavigate, super.key});

  final AdminNavigationCallback onNavigate;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _overdueAlerts = true;
  bool _findingAlerts = true;
  bool _approvalAlerts = true;
  bool _compactCharts = false;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      onNavigate: widget.onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminPageHeading(
            eyebrow: 'Administrator preferences',
            title: 'Settings',
            description: 'Choose how the mobile workspace presents oversight alerts and reporting information.',
          ),
          AdminSurfaceCard(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.access_time_rounded,
                  title: 'Overdue audit alerts',
                  description: 'Notify the GM when 5S or BOM submissions pass their deadlines.',
                  value: _overdueAlerts,
                  onChanged: (value) => setState(() => _overdueAlerts = value),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _SettingRow(
                  icon: Icons.warning_amber_rounded,
                  title: 'Critical finding alerts',
                  description:
                      'Receive immediate notices for NO and N/A judgments.',
                  value: _findingAlerts,
                  onChanged: (value) => setState(() => _findingAlerts = value),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _SettingRow(
                  icon: Icons.description_outlined,
                  title: 'Checklist approval alerts',
                  description:
                      'Notify the GM when a BOM submits a master-form change.',
                  value: _approvalAlerts,
                  onChanged: (value) => setState(() => _approvalAlerts = value),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _SettingRow(
                  icon: Icons.bar_chart_outlined,
                  title: 'Compact report charts',
                  description: 'Use denser report cards when viewing the app on the web.',
                  value: _compactCharts,
                  onChanged: (value) => setState(() => _compactCharts = value),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GacColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GacColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: GacColors.black,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'These settings update the interface state. Connect them to persistent storage after the administrator settings API is available.',
                    style: TextStyle(
                      color: GacColors.gray,
                      fontSize: 8,
                      height: 13 / 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 41,
              height: 41,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GacColors.black,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: GacColors.white),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 8,
                        height: 13 / 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: GacColors.black,
              activeThumbColor: GacColors.white,
              inactiveTrackColor: const Color(0xFFD5D5D5),
              inactiveThumbColor: GacColors.white,
            ),
          ],
        ),
      ),
    );
  }
}
