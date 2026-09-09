import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../services/share_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_segmented_switcher.dart';
import '../widgets/admin_ui.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({required this.onNavigate, this.onShare, super.key});

  final AdminNavigationCallback onNavigate;
  final ShareTextCallback? onShare;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _branchController = TextEditingController(
    text: 'Pasong Tamo',
  );

  late List<AdminUserData> _users;
  late List<ApprovalRequestData> _approvals;
  String _search = '';
  String _roleFilter = 'ALL';
  String _newRole = '5S_SALES';

  @override
  void initState() {
    super.initState();
    _users = List<AdminUserData>.of(adminUsers);
    _approvals = List<ApprovalRequestData>.of(approvalRequests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  List<AdminUserData> get _visibleUsers {
    final query = _search.trim().toLowerCase();
    return _users
        .where((user) {
          final roleMatches = _roleFilter == 'ALL' || user.role == _roleFilter;
          final searchable =
              '${user.name} ${user.email} ${user.branch} ${user.roleLabel}'
                  .toLowerCase();
          return roleMatches && (query.isEmpty || searchable.contains(query));
        })
        .toList(growable: false);
  }

  int get _fiveSCount =>
      _users.where((user) => user.role.startsWith('5S') || user.role == 'PIC').length;
  int get _bomCount => _users.where((user) => user.role == 'BOM').length;
  int get _activeToday => _users
      .where(
        (user) => user.status == 'Active' && user.lastActive != 'Yesterday',
      )
      .length;
  int get _overdueTasks => _users.fold(0, (sum, user) => sum + user.overdue);
  int get _pendingApprovals =>
      _approvals.where((approval) => approval.status == 'Pending').length;

  Future<void> _showAlert(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetNewUser() {
    _nameController.clear();
    _emailController.clear();
    _branchController.text = 'Pasong Tamo';
    _newRole = '5S_SALES';
  }

  String _roleLabel(String role) => switch (role) {
    '5S_UTILITIES' => '5S Utilities',
    '5S_SERVICE' => '5S Service',
    '5S_SALES' => '5S Sales',
    'PIC' => '5S Inspector',
    'BOM' => 'Branch Operations Manager',
    _ => 'General Manager',
  };

  String _initialsFor(String name) {
    return name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }

  Future<void> _saveUser(BuildContext modalContext) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final branch = _branchController.text.trim();
    if (name.isEmpty || email.isEmpty || branch.isEmpty) {
      await _showAlert(
        'Complete the account',
        'Name, email, and branch are required.',
      );
      return;
    }

    final nextUser = AdminUserData(
      id: '$_newRole-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      initials: _initialsFor(name).isEmpty ? _newRole : _initialsFor(name),
      role: _newRole,
      roleLabel: _roleLabel(_newRole),
      branch: _newRole == 'GM' ? 'All Branches' : branch,
      status: 'Active',
      usage: 0,
      assigned: 0,
      completed: 0,
      overdue: 0,
      lastActive: 'Not yet active',
    );

    setState(() => _users = [nextUser, ..._users]);
    if (modalContext.mounted) Navigator.of(modalContext).pop();
    _resetNewUser();
    if (mounted) {
      await _showAlert(
        'User added',
        '${nextUser.name} can now be connected to your API.',
      );
    }
  }

  Future<void> _openAddUserModal() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x9E000000),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, modalSetState) {
          void setRole(String role) {
            modalSetState(() => _newRole = role);
          }

          return FractionallySizedBox(
            heightFactor: 0.88,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Material(
                  color: GacColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minHeight: 76),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        color: GacColors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACCOUNT MANAGEMENT',
                                  style: TextStyle(
                                    color: GacColors.muted,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add User',
                                  style: TextStyle(
                                    color: GacColors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: GacColors.charcoal,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => Navigator.of(modalContext).pop(),
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox.square(
                                  dimension: 38,
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: GacColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            18,
                            18,
                            18,
                            30 + MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          children: [
                            const _InputLabel('FULL NAME'),
                            _ModalTextField(
                              controller: _nameController,
                              hint: 'Employee name',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 11),
                            const _InputLabel('EMAIL ADDRESS'),
                            _ModalTextField(
                              controller: _emailController,
                              hint: 'name@gateway.com',
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                            ),
                            const SizedBox(height: 11),
                            const _InputLabel('SYSTEM ROLE'),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (final role in const [
                                  '5S_UTILITIES',
                                  '5S_SERVICE',
                                  '5S_SALES',
                                  'BOM',
                                  'GM',
                                ])
                                  _FilterChip(
                                    label: _roleLabel(role),
                                    selected: _newRole == role,
                                    onTap: () => setRole(role),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 11),
                            const _InputLabel('BRANCH'),
                            Opacity(
                              opacity: _newRole == 'GM' ? 0.55 : 1,
                              child: _ModalTextField(
                                controller: _branchController,
                                hint: _newRole == 'GM'
                                    ? 'All Branches'
                                    : 'Pasong Tamo',
                                enabled: _newRole != 'GM',
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 9,
                              runSpacing: 9,
                              children: [
                                AdminActionButton(
                                  label: 'Cancel',
                                  onPressed: () =>
                                      Navigator.of(modalContext).pop(),
                                ),
                                AdminActionButton(
                                  label: 'Save User',
                                  icon: Icons.person_add_alt_1_outlined,
                                  variant: AdminActionButtonVariant.primary,
                                  onPressed: () => _saveUser(modalContext),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareUsers() async {
    final rows = _users
        .map(
          (user) =>
              '${user.name} | ${user.role} | ${user.branch} | Usage ${user.usage}% | ${user.completed}/${user.assigned} tasks',
        )
        .join('\n');
    final text = 'Gateway user usage report\n\n$rows';
    final callback = widget.onShare;
    if (callback != null) {
      await callback(text);
    } else if (mounted) {
      await shareText(context, text);
    }
  }

  void _updateApproval(String id, String status) {
    setState(() {
      _approvals = _approvals
          .map(
            (approval) => approval.id == id
                ? approval.copyWith(status: status)
                : approval,
          )
          .toList(growable: false);
    });
    _showAlert(
      'Change ${status.toLowerCase()}',
      'The decision has been recorded in the mobile prototype.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _visibleUsers;
    return AdminPage(
      onNavigate: widget.onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminReportsUsersSwitcher(
            activeView: AdminDestination.users,
            onChanged: widget.onNavigate,
          ),
          AdminPageHeading(
            eyebrow: 'General Manager access',
            title: 'User Management',
            description: 'Oversee PIC and BOM usage, audit account activity, notify users about unfinished tasks, and review checklist changes requested by branch managers.',
            action: AdminActionButton(
              label: 'Add User',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _openAddUserModal,
              variant: AdminActionButtonVariant.primary,
              compact: true,
            ),
          ),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              AdminActionButton(
                label: 'Share User Report',
                icon: Icons.share_outlined,
                onPressed: _shareUsers,
              ),
              AdminActionButton(
                label: 'Send Notification',
                icon: Icons.send_outlined,
                onPressed: () => _showAlert(
                  'Notification composer',
                  'Select a user below and tap Notify, or connect this action to your Laravel notification endpoint.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _MetricGrid(
            children: [
              AdminMetricCard(
                label: 'Total Accounts',
                value: '${_users.length}',
                detail: 'GM, BOM, and 5S accounts',
                icon: Icons.people_outline_rounded,
              ),
              AdminMetricCard(
                label: '5S Accounts',
                value: '$_fiveSCount',
                detail: 'Conduct assigned 5S tasks',
                icon: Icons.person_outline_rounded,
              ),
              AdminMetricCard(
                label: 'BOM Accounts',
                value: '$_bomCount',
                detail: 'Oversee branch 5S activity',
                icon: Icons.business_center_outlined,
              ),
              AdminMetricCard(
                label: 'Active Today',
                value: '$_activeToday',
                detail: 'Recently active accounts',
                icon: Icons.monitor_heart_outlined,
              ),
              AdminMetricCard(
                label: 'Overdue Tasks',
                value: '$_overdueTasks',
                detail: 'Tasks requiring follow-up',
                icon: Icons.access_time_rounded,
              ),
              AdminMetricCard(
                label: 'Pending Approvals',
                value: '$_pendingApprovals',
                detail: 'BOM checklist changes',
                icon: Icons.description_outlined,
              ),
            ],
          ),
          AdminSurfaceCard(
            margin: const EdgeInsets.only(top: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 47),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: GacColors.offWhite,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: GacColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: GacColors.gray,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _search = value),
                          style: const TextStyle(
                            color: GacColors.black,
                            fontSize: 10,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search name, email, branch, or role...',
                            hintStyle: TextStyle(
                              color: GacColors.muted,
                              fontSize: 10,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_search.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 19,
                            color: GacColors.gray,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final role in const [
                      'ALL',
                      '5S_UTILITIES',
                      '5S_SERVICE',
                      '5S_SALES',
                      'BOM',
                      'GM',
                    ])
                      _FilterChip(
                        label: role == 'ALL' ? 'All roles' : _roleLabel(role),
                        selected: _roleFilter == role,
                        onTap: () => setState(() => _roleFilter = role),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AdminSectionHeading(
            eyebrow: 'Directory',
            title: 'User Accounts',
            detail: 'Roles, branches, access status, usage, and checklist completion',
            action: AdminStatusPill(label: '${visibleUsers.length} users'),
          ),
          if (visibleUsers.isEmpty)
            const _EmptyUsersCard()
          else
            for (var index = 0; index < visibleUsers.length; index++) ...[
              _UserCard(
                user: visibleUsers[index],
                onNotify: () => _showAlert(
                  'Notify ${visibleUsers[index].name}',
                  'Connect this button to your notification API endpoint.',
                ),
                onAudit: () => _showAlert(
                  'Audit ${visibleUsers[index].name}',
                  'Usage ${visibleUsers[index].usage}% · ${visibleUsers[index].overdue} overdue tasks · Last active ${visibleUsers[index].lastActive}',
                ),
                onEdit: () => _showAlert(
                  'Edit account',
                  'Connect this action to your Laravel user update endpoint.',
                ),
              ),
              if (index != visibleUsers.length - 1) const SizedBox(height: 10),
            ],
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Horizontal comparison',
            title: '5S & BOM Usage',
            detail: 'System usage and checklist completion visible to the General Manager',
          ),
          AdminSurfaceCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _users.where((user) => user.role != 'GM').length;
                  index++
                ) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: GacColors.lightGray,
                    ),
                  _UsageRow(
                    user: _users
                        .where((user) => user.role != 'GM')
                        .elementAt(index),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Account distribution',
            title: 'Role Overview',
            detail: 'Current role counts and General Manager access',
          ),
          AdminSurfaceCard(
            child: Column(
              children: [
                _RoleOverviewRow(
                  label: '5S Utilities',
                  count: _users.where((u) => u.role == '5S_UTILITIES').length,
                  total: _users.length,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _RoleOverviewRow(
                  label: '5S Service',
                  count: _users.where((u) => u.role == '5S_SERVICE').length,
                  total: _users.length,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _RoleOverviewRow(
                  label: '5S Sales',
                  count: _users.where((u) => u.role == '5S_SALES').length,
                  total: _users.length,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _RoleOverviewRow(
                  label: 'Branch Operations Manager',
                  count: _bomCount,
                  total: _users.length,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: GacColors.lightGray,
                ),
                _RoleOverviewRow(
                  label: 'General Manager',
                  count: _users.where((u) => u.role == 'GM' || u.role == 'ADMIN').length,
                  total: _users.length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Permissions',
            title: 'Role Capability Matrix',
            detail: 'The desktop permission table reorganized as readable mobile cards',
          ),
          for (var index = 0; index < capabilities.length; index++) ...[
            _CapabilityCard(capability: capabilities[index], number: index + 1),
            if (index != capabilities.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 28),
          AdminSectionHeading(
            eyebrow: 'GM decision',
            title: 'BOM Checklist Change Requests',
            detail: 'Proposed edits remain pending until approved or rejected',
            action: AdminStatusPill(
              label: '$_pendingApprovals pending',
              tone: _pendingApprovals > 0
                  ? AdminStatusTone.warning
                  : AdminStatusTone.success,
            ),
          ),
          for (var index = 0; index < _approvals.length; index++) ...[
            _ApprovalCard(
              approval: _approvals[index],
              onReject: () => _updateApproval(_approvals[index].id, 'Rejected'),
              onApprove: () =>
                  _updateApproval(_approvals[index].id, 'Approved'),
            ),
            if (index != _approvals.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 28),
          const AdminSectionHeading(
            eyebrow: 'Latest events',
            title: 'Recent User Activity',
            detail: 'GM, BOM, and 5S usage events',
          ),
          AdminSurfaceCard(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < recentActivities.length;
                  index++
                ) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: GacColors.lightGray,
                    ),
                  _ActivityRow(activity: recentActivities[index]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 540 ? 2 : 3;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? GacColors.black : GacColors.offWhite,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? GacColors.black : GacColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? GacColors.white : GacColors.gray,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onNotify,
    required this.onAudit,
    required this.onEdit,
  });

  final AdminUserData user;
  final VoidCallback onNotify;
  final VoidCallback onAudit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final completion = user.assigned == 0
        ? 0
        : (user.completed / user.assigned * 100).round();
    final statusTone = switch (user.status) {
      'Active' => AdminStatusTone.success,
      'Suspended' => AdminStatusTone.danger,
      _ => AdminStatusTone.neutral,
    };

    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GacColors.black,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: GacColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: GacColors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: GacColors.gray,
                          fontSize: 8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${user.roleLabel} · ${user.branch}',
                        style: const TextStyle(
                          color: GacColors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AdminStatusPill(label: user.status, tone: statusTone),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _UserMetricBox(
                  label: 'USAGE',
                  value: '${user.usage}%',
                  progress: user.usage.toDouble(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UserMetricBox(
                  label: 'TASKS',
                  value: '${user.completed}/${user.assigned}',
                  progress: completion.toDouble(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _UserMetricBox(
                  label: 'OVERDUE',
                  value: '${user.overdue}',
                  danger: user.overdue > 0,
                  detail: user.lastActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              AdminActionButton(
                label: 'Notify',
                icon: Icons.send_outlined,
                onPressed: onNotify,
                compact: true,
              ),
              AdminActionButton(
                label: 'Audit',
                icon: Icons.shield_outlined,
                onPressed: onAudit,
                variant: AdminActionButtonVariant.primary,
                compact: true,
              ),
              AdminActionButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserMetricBox extends StatelessWidget {
  const _UserMetricBox({
    required this.label,
    required this.value,
    this.progress,
    this.detail,
    this.danger = false,
  });

  final String label;
  final String value;
  final double? progress;
  final String? detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 79),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GacColors.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: danger ? GacColors.error : GacColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 7),
            AdminProgressBar(value: progress!),
          ],
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: const TextStyle(color: GacColors.gray, fontSize: 7),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyUsersCard extends StatelessWidget {
  const _EmptyUsersCard();

  @override
  Widget build(BuildContext context) {
    return const AdminSurfaceCard(
      padding: EdgeInsets.symmetric(horizontal: 17, vertical: 30),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 28, color: GacColors.gray),
          SizedBox(height: 10),
          Text(
            'No matching accounts',
            style: TextStyle(
              color: GacColors.black,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Reset the search or role filter.',
            style: TextStyle(color: GacColors.gray, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.user});

  final AdminUserData user;

  @override
  Widget build(BuildContext context) {
    final completion = user.assigned == 0
        ? 0.0
        : (user.completed / user.assigned * 100).roundToDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: GacColors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${user.role} · ${user.branch}',
                      style: const TextStyle(
                        color: GacColors.gray,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${user.usage}% usage',
                style: const TextStyle(
                  color: GacColors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _LabeledProgress(label: 'Use', value: user.usage.toDouble()),
          _LabeledProgress(
            label: 'Tasks',
            value: completion,
            color: const Color(0xFF8E8E8E),
          ),
        ],
      ),
    );
  }
}

class _LabeledProgress extends StatelessWidget {
  const _LabeledProgress({
    required this.label,
    required this.value,
    this.color = GacColors.black,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 23),
      child: Row(
        children: [
          SizedBox(
            width: 29,
            child: Text(
              label,
              style: const TextStyle(
                color: GacColors.gray,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: AdminProgressBar(value: value, height: 7, fillColor: color),
          ),
        ],
      ),
    );
  }
}

class _RoleOverviewRow extends StatelessWidget {
  const _RoleOverviewRow({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : count / total * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: GacColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          AdminProgressBar(value: value),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.capability, required this.number});

  final CapabilityData capability;
  final int number;

  @override
  Widget build(BuildContext context) {
    return AdminSurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GacColors.black,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: GacColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  capability.title,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 11,
                    height: 15 / 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _CapabilityRow(role: '5S', value: capability.pic),
          const SizedBox(height: 6),
          _CapabilityRow(role: 'BOM', value: capability.bom),
          const SizedBox(height: 6),
          _CapabilityRow(role: 'GM', value: capability.gm, emphasized: true),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.role,
    required this.value,
    this.emphasized = false,
  });

  final String role;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: GacColors.offWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              role,
              style: const TextStyle(
                color: GacColors.gray,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: emphasized ? GacColors.black : GacColors.gray,
                fontSize: 8,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.approval,
    required this.onReject,
    required this.onApprove,
  });

  final ApprovalRequestData approval;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final tone = switch (approval.status) {
      'Pending' => AdminStatusTone.warning,
      'Approved' => AdminStatusTone.success,
      _ => AdminStatusTone.danger,
    };
    return AdminSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GacColors.black,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  approval.module,
                  style: const TextStyle(
                    color: GacColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approval.title,
                        style: const TextStyle(
                          color: GacColors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${approval.requestedBy} · ${approval.date}',
                        style: const TextStyle(
                          color: GacColors.gray,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AdminStatusPill(label: approval.status, tone: tone),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 13),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: GacColors.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROPOSED WORDING',
                  style: TextStyle(
                    color: GacColors.gray,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  approval.proposedText,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 9,
                    height: 14 / 9,
                  ),
                ),
              ],
            ),
          ),
          if (approval.status == 'Pending') ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  onPressed: onReject,
                  variant: AdminActionButtonVariant.danger,
                  compact: true,
                ),
                AdminActionButton(
                  label: 'Approve Change',
                  icon: Icons.check_rounded,
                  onPressed: onApprove,
                  variant: AdminActionButtonVariant.primary,
                  compact: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 67),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: GacColors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.user,
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.action,
                  style: const TextStyle(
                    color: GacColors.gray,
                    fontSize: 8,
                    height: 13 / 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: const TextStyle(color: GacColors.muted, fontSize: 7),
          ),
        ],
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: GacColors.gray,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ModalTextField extends StatelessWidget {
  const _ModalTextField({
    required this.controller,
    required this.hint,
    required this.textInputAction,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.autocorrect = true,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      style: const TextStyle(color: GacColors.black, fontSize: 10),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: GacColors.muted, fontSize: 10),
        filled: true,
        fillColor: GacColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: GacColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: GacColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: GacColors.black),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: GacColors.border),
        ),
      ),
    );
  }
}
