export 'dos_aftersales_data.dart';
export 'dos_sales_data.dart';
export 'dos_documentation_data.dart';
export 'dos_subform_data.dart';

class ComplianceMonth {
  const ComplianceMonth({
    required this.month,
    required this.overall,
    required this.dos,
    required this.fiveS,
    required this.audits,
    required this.findings,
  });

  final String month;
  final int overall;
  final int dos;
  final int fiveS;
  final int audits;
  final int findings;
}

class ProgressMetric {
  const ProgressMetric({required this.label, required this.value, this.detail});

  final String label;
  final int value;
  final String? detail;
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.user,
    required this.action,
    required this.status,
    required this.time,
  });

  final String id;
  final String user;
  final String action;
  final String status;
  final String time;
}

class BranchMetric {
  const BranchMetric({
    required this.rank,
    required this.branch,
    required this.compliance,
    required this.dos,
    required this.fiveS,
    required this.status,
  });

  final int rank;
  final String branch;
  final int compliance;
  final int dos;
  final int fiveS;
  final String status;
}

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.text,
    this.subject,
    this.level,
    this.response,
    this.coverage,
    this.bomTask,
    this.escalation,
    this.checker = 'Sales Manager',
    this.finding,
    this.actionPlan,
    this.commitmentDate,
    this.howToCheck,
  });

  final String id;
  final String text;
  final String? subject;
  final String? level;
  final String? response;
  final String? coverage;
  final String? bomTask;
  final String? escalation;
  final String? checker;
  final String? finding;
  final String? actionPlan;
  final String? commitmentDate;
  final String? howToCheck;

  ChecklistItem copyWith({
    String? id,
    String? text,
    String? subject,
    String? level,
    String? response,
    String? coverage,
    String? bomTask,
    String? escalation,
    String? checker,
    String? finding,
    String? actionPlan,
    String? commitmentDate,
    String? howToCheck,
    bool clearSubject = false,
    bool clearLevel = false,
    bool clearResponse = false,
    bool clearCoverage = false,
    bool clearBomTask = false,
    bool clearEscalation = false,
    bool clearFinding = false,
    bool clearActionPlan = false,
    bool clearCommitmentDate = false,
    bool clearHowToCheck = false,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subject: clearSubject ? null : subject ?? this.subject,
      level: clearLevel ? null : level ?? this.level,
      response: clearResponse ? null : response ?? this.response,
      coverage: clearCoverage ? null : coverage ?? this.coverage,
      bomTask: clearBomTask ? null : bomTask ?? this.bomTask,
      escalation: clearEscalation ? null : escalation ?? this.escalation,
      checker: checker ?? this.checker,
      finding: clearFinding ? null : finding ?? this.finding,
      actionPlan: clearActionPlan ? null : actionPlan ?? this.actionPlan,
      commitmentDate: clearCommitmentDate
          ? null
          : commitmentDate ?? this.commitmentDate,
      howToCheck: clearHowToCheck ? null : howToCheck ?? this.howToCheck,
    );
  }
}

class ChecklistSection {
  const ChecklistSection({
    required this.id,
    required this.title,
    required this.items,
  });

  final String id;
  final String title;
  final List<ChecklistItem> items;

  ChecklistSection copyWith({
    String? id,
    String? title,
    List<ChecklistItem>? items,
  }) {
    return ChecklistSection(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
}

class AdminUserData {
  const AdminUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
    required this.role,
    required this.roleLabel,
    required this.branch,
    required this.status,
    required this.usage,
    required this.assigned,
    required this.completed,
    required this.overdue,
    required this.lastActive,
  });

  final String id;
  final String name;
  final String email;
  final String initials;
  final String role;
  final String roleLabel;
  final String branch;
  final String status;
  final int usage;
  final int assigned;
  final int completed;
  final int overdue;
  final String lastActive;

  AdminUserData copyWith({
    String? id,
    String? name,
    String? email,
    String? initials,
    String? role,
    String? roleLabel,
    String? branch,
    String? status,
    int? usage,
    int? assigned,
    int? completed,
    int? overdue,
    String? lastActive,
  }) {
    return AdminUserData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      roleLabel: roleLabel ?? this.roleLabel,
      branch: branch ?? this.branch,
      status: status ?? this.status,
      usage: usage ?? this.usage,
      assigned: assigned ?? this.assigned,
      completed: completed ?? this.completed,
      overdue: overdue ?? this.overdue,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class ApprovalRequestData {
  const ApprovalRequestData({
    required this.id,
    required this.title,
    required this.module,
    required this.requestedBy,
    required this.branch,
    required this.date,
    required this.status,
    required this.proposedText,
  });

  final String id;
  final String title;
  final String module;
  final String requestedBy;
  final String branch;
  final String date;
  final String status;
  final String proposedText;

  ApprovalRequestData copyWith({String? status}) {
    return ApprovalRequestData(
      id: id,
      title: title,
      module: module,
      requestedBy: requestedBy,
      branch: branch,
      date: date,
      status: status ?? this.status,
      proposedText: proposedText,
    );
  }
}

class CapabilityData {
  const CapabilityData({
    required this.title,
    required this.pic,
    required this.bom,
    required this.gm,
  });

  final String title;
  final String pic;
  final String bom;
  final String gm;
}

const monthlyCompliance = <ComplianceMonth>[
  ComplianceMonth(
    month: 'Mar',
    overall: 81,
    dos: 80,
    fiveS: 83,
    audits: 18,
    findings: 14,
  ),
  ComplianceMonth(
    month: 'Apr',
    overall: 84,
    dos: 83,
    fiveS: 86,
    audits: 21,
    findings: 12,
  ),
  ComplianceMonth(
    month: 'May',
    overall: 87,
    dos: 86,
    fiveS: 89,
    audits: 24,
    findings: 11,
  ),
  ComplianceMonth(
    month: 'Jun',
    overall: 89,
    dos: 88,
    fiveS: 91,
    audits: 25,
    findings: 10,
  ),
  ComplianceMonth(
    month: 'Jul',
    overall: 91,
    dos: 90,
    fiveS: 93,
    audits: 27,
    findings: 9,
  ),
  ComplianceMonth(
    month: 'Aug',
    overall: 92,
    dos: 91,
    fiveS: 94,
    audits: 28,
    findings: 9,
  ),
];

const dosCategories = <ProgressMetric>[
  ProgressMetric(label: 'Facilities', value: 93, detail: '15 standards'),
  ProgressMetric(label: 'Systems', value: 98, detail: '4 standards'),
  ProgressMetric(label: 'Lead Generation', value: 88, detail: '6 standards'),
  ProgressMetric(label: 'Vehicle Release', value: 91, detail: '8 standards'),
  ProgressMetric(
    label: 'Customer Engagement',
    value: 95,
    detail: '12 standards',
  ),
];

const fiveSSections = <ProgressMetric>[
  ProgressMetric(label: 'Parking Area', value: 96, detail: '2 items'),
  ProgressMetric(label: 'Showroom', value: 94, detail: '9 items'),
  ProgressMetric(label: 'Service Reception', value: 91, detail: '8 items'),
  ProgressMetric(label: 'Working Bay', value: 87, detail: '7 items'),
  ProgressMetric(label: 'Customer Lounge', value: 93, detail: '6 items'),
];

const recentActivities = <ActivityItem>[
  ActivityItem(
    id: 'activity-1',
    user: 'Juan Dela Cruz',
    action: 'DOS audit submitted',
    status: 'Completed',
    time: '12 min ago',
  ),
  ActivityItem(
    id: 'activity-2',
    user: 'Maria Santos',
    action: 'Daily 5S checklist',
    status: 'Completed',
    time: '34 min ago',
  ),
  ActivityItem(
    id: 'activity-3',
    user: 'Pasong Tamo BOM',
    action: 'Checklist change requested',
    status: 'Pending',
    time: '1 hr ago',
  ),
  ActivityItem(
    id: 'activity-4',
    user: 'Pedro Reyes',
    action: 'DOS finding requires review',
    status: 'Flagged',
    time: '2 hrs ago',
  ),
];

const branches = <BranchMetric>[
  BranchMetric(
    rank: 1,
    branch: 'Sucat',
    compliance: 96,
    dos: 95,
    fiveS: 97,
    status: 'Excellent',
  ),
  BranchMetric(
    rank: 2,
    branch: 'Cavite',
    compliance: 93,
    dos: 92,
    fiveS: 95,
    status: 'Excellent',
  ),
  BranchMetric(
    rank: 3,
    branch: 'Pasong Tamo',
    compliance: 91,
    dos: 90,
    fiveS: 93,
    status: 'Good',
  ),
  BranchMetric(
    rank: 4,
    branch: 'Gateway Branch 2',
    compliance: 88,
    dos: 87,
    fiveS: 90,
    status: 'Needs review',
  ),
];

const fiveSTemplate = <ChecklistSection>[
  ChecklistSection(
    id: 'five-s-parking',
    title: 'Parking Area',
    items: [
      ChecklistItem(
        id: '5s-1',
        text: 'Is the parking area visible and easy to find, with defined lines and proper signage?',
        response: 'YES',
      ),
      ChecklistItem(
        id: '5s-2',
        text:
            'Is the parking area clean, free from debris, and well maintained?',
        response: 'YES',
      ),
    ],
  ),
  ChecklistSection(
    id: 'five-s-showroom',
    title: 'Showroom / Sales Negotiation Area',
    items: [
      ChecklistItem(
        id: '5s-3',
        text: 'Is the area clean and organized, with no unnecessary items on the floor?',
        response: 'YES',
      ),
      ChecklistItem(
        id: '5s-4',
        text: 'Are there no broken or damaged tiles?',
        response: 'NO',
      ),
      ChecklistItem(
        id: '5s-5',
        text: 'Are all showroom lights functioning properly?',
      ),
    ],
  ),
  ChecklistSection(
    id: 'five-s-service',
    title: 'Service Working Bay',
    items: [
      ChecklistItem(
        id: '5s-33',
        text: 'Is the working bay clean, free from waste, and properly sanitized?',
        response: 'YES',
      ),
      ChecklistItem(
        id: '5s-34',
        text: 'Are trolleys stored inside the painted bay with unnecessary personal items removed?',
      ),
      ChecklistItem(
        id: '5s-38',
        text: 'Are tools organized, complete, and returned to their proper locations?',
        response: 'YES',
      ),
    ],
  ),
  ChecklistSection(
    id: 'five-s-lounge',
    title: 'Customer Lounge',
    items: [
      ChecklistItem(
        id: '5s-48',
        text: 'Are complimentary snacks available?',
        response: 'YES',
      ),
      ChecklistItem(
        id: '5s-50',
        text: 'Are seats and sofas comfortable, undamaged, and sanitized?',
      ),
      ChecklistItem(
        id: '5s-53',
        text: 'Is free Wi-Fi available and accessible to customers?',
        response: 'N/A',
      ),
    ],
  ),
];

const adminUsers = <AdminUserData>[
  AdminUserData(
    id: 'GM-001',
    name: 'General Manager',
    email: 'gm@gateway.local',
    initials: 'GM',
    role: 'GM',
    roleLabel: 'General Manager',
    branch: 'All Branches',
    status: 'Active',
    usage: 96,
    assigned: 18,
    completed: 18,
    overdue: 0,
    lastActive: 'Now',
  ),
  AdminUserData(
    id: 'BOM-PT',
    name: 'Pasong Tamo BOM',
    email: 'bom.pasongtamo@gateway.local',
    initials: 'PB',
    role: 'BOM',
    roleLabel: 'Branch Operations Manager',
    branch: 'Pasong Tamo',
    status: 'Active',
    usage: 89,
    assigned: 28,
    completed: 26,
    overdue: 2,
    lastActive: '1 hr ago',
  ),
  AdminUserData(
    id: 'BOM-B2',
    name: 'Gateway Branch 2 BOM',
    email: 'bom.branch2@gateway.local',
    initials: 'GB',
    role: 'BOM',
    roleLabel: 'Branch Operations Manager',
    branch: 'Gateway Branch 2',
    status: 'Active',
    usage: 82,
    assigned: 24,
    completed: 22,
    overdue: 2,
    lastActive: '4 hrs ago',
  ),
  AdminUserData(
    id: '5S-UTIL',
    name: 'Utilities Specialist',
    email: 'utilities@gateway.local',
    initials: 'UT',
    role: '5S_UTILITIES',
    roleLabel: '5S Utilities',
    branch: 'Pasong Tamo',
    status: 'Active',
    usage: 91,
    assigned: 31,
    completed: 30,
    overdue: 1,
    lastActive: '48 min ago',
  ),
  AdminUserData(
    id: '5S-SRV',
    name: 'Service 5S Inspector',
    email: 'service@gateway.local',
    initials: 'SV',
    role: '5S_SERVICE',
    roleLabel: '5S Service',
    branch: 'Pasong Tamo',
    status: 'Active',
    usage: 85,
    assigned: 27,
    completed: 25,
    overdue: 2,
    lastActive: '2 hrs ago',
  ),
  AdminUserData(
    id: '5S-SLS',
    name: 'Sales 5S Inspector',
    email: 'sales@gateway.local',
    initials: 'SL',
    role: '5S_SALES',
    roleLabel: '5S Sales',
    branch: 'Gateway Branch 2',
    status: 'Active',
    usage: 78,
    assigned: 24,
    completed: 23,
    overdue: 1,
    lastActive: '6 hrs ago',
  ),
];

const approvalRequests = <ApprovalRequestData>[
  ApprovalRequestData(
    id: 'REQ-001',
    title: 'Update appointment verification',
    module: 'DOS',
    requestedBy: 'Pasong Tamo BOM',
    branch: 'Pasong Tamo',
    date: 'Aug 10, 2026',
    status: 'Pending',
    proposedText: 'Confirm the appointment one day before and record the result in the booking system.',
  ),
  ApprovalRequestData(
    id: 'REQ-002',
    title: 'Add charging-station check',
    module: '5S',
    requestedBy: 'Gateway Branch 2 BOM',
    branch: 'Gateway Branch 2',
    date: 'Aug 10, 2026',
    status: 'Pending',
    proposedText: 'Verify that the customer charging station is clean, labeled, and functioning.',
  ),
];

const capabilities = <CapabilityData>[
  CapabilityData(
    title: 'Conduct assigned checklist tasks',
    pic: 'Allowed',
    bom: 'Oversight only',
    gm: 'Audit access',
  ),
  CapabilityData(
    title: 'View user usage',
    pic: 'Own usage',
    bom: 'Branch 5S',
    gm: 'All BOMs & 5S',
  ),
  CapabilityData(
    title: 'Generate daily and monthly reports',
    pic: 'Not assigned',
    bom: 'Branch reports',
    gm: 'All branches',
  ),
  CapabilityData(
    title: 'Edit checklist templates',
    pic: 'Not allowed',
    bom: 'Needs GM approval',
    gm: 'Direct edit',
  ),
  CapabilityData(
    title: 'Approve BOM checklist changes',
    pic: 'Not allowed',
    bom: 'Request only',
    gm: 'Final approval',
  ),
  CapabilityData(
    title: 'Audit user activity',
    pic: 'Not allowed',
    bom: '5S oversight',
    gm: 'Audit BOM & 5S',
  ),
];
