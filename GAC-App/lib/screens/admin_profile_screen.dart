import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_ui.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({
    required this.onNavigate,
    required this.onSignOut,
    super.key,
  });

  final AdminNavigationCallback onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      onNavigate: onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminPageHeading(
            eyebrow: 'Administrator account',
            title: 'Profile',
            description: 'General Manager access and oversight assignment.',
          ),
          AdminSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 25),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: GacColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'GM',
                    style: TextStyle(
                      color: GacColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'General Manager',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GacColors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'ADMINISTRATOR',
                  style: TextStyle(
                    color: GacColors.gray,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 13),
                const AdminStatusPill(
                  label: 'Active account',
                  tone: AdminStatusTone.success,
                ),
              ],
            ),
          ),
          AdminSurfaceCard(
            margin: const EdgeInsets.only(top: 12),
            child: Column(
              children: const [
                _ProfileDetailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email address',
                  value: 'gm@gateway.local',
                ),
                Divider(height: 1, thickness: 1, color: GacColors.lightGray),
                _ProfileDetailRow(
                  icon: Icons.business_outlined,
                  label: 'Assigned coverage',
                  value: 'All Gateway branches',
                ),
                Divider(height: 1, thickness: 1, color: GacColors.lightGray),
                _ProfileDetailRow(
                  icon: Icons.shield_outlined,
                  label: 'Account type',
                  value: 'General Manager',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileSummaryCard(
                  label: 'AUDITS REVIEWED',
                  value: '28',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ProfileSummaryCard(label: 'APPROVALS', value: '12'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: 'Sign out',
            excludeSemantics: true,
            child: Material(
              color: GacColors.black,
              borderRadius: BorderRadius.circular(15),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onSignOut,
                child: const SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: GacColors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SIGN OUT',
                        style: TextStyle(
                          color: GacColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 67),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GacColors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: GacColors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: GacColors.black,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
