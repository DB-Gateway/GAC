/// Returns the canonical user type used for Workshop Supervisor accounts.
///
/// `WS` and `WORKSHOP` are accepted only as legacy API/session values so
/// existing accounts keep working while the server data is migrated.
String normalizeUserType(String userType) {
  final trimmed = userType.trim();
  final normalized = trimmed
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  return switch (normalized) {
    'WS' ||
    'WORKSHOP' ||
    'WS SUP' ||
    'WORKSHOP SUP' ||
    'WORKSHOP SUPERVISOR' ||
    'WORSHOP SUP' ||
    'WORSHOP SUPERVISOR' => 'WS SUP',
    _ => trimmed,
  };
}

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.accountStatus,
    this.branch,
    this.picAssignmentType,
    this.picAssignmentLabel,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String? branch;
  final String userType;
  final String? picAssignmentType;
  final String? picAssignmentLabel;
  final String accountStatus;
  final String? avatarUrl;

  String get canonicalUserType => normalizeUserType(userType);

  static const fallback = AuthenticatedUser(
    id: 0,
    name: 'Gateway User',
    email: '',
    userType: 'PIC',
    accountStatus: 'active',
  );

  String get roleLabel => switch (canonicalUserType.toUpperCase()) {
    'PIC' || 'PERSON IN CHARGE' => 'Person In Charge',
    'SM' ||
    'SALES MANAGER' ||
    'SALES_MANAGER' ||
    'SALES MGR' ||
    'DOS_SALES' ||
    'DOS-SALES' ||
    'DOS SALES' => 'Sales Manager',
    'ASM' ||
    'AFTERSALES MANAGER' ||
    'AFTERSALES_MANAGER' ||
    'AS MGR' ||
    'DOS_AFTERSALES' ||
    'DOS-AFTERSALES' ||
    'DOS AFTERSALES' => 'Aftersales Manager',
    'CE SERVICE' || 'CE_SERVICE' || 'CE' => 'Customer Experience (CE) Service',
    'JC' || 'JOB CONTROLLER' || 'JOB_CONTROLLER' => 'Job Controller',
    'PARTS SUPERVISOR' || 'PARTS_SUPERVISOR' || 'PARTS' => 'Parts Supervisor',
    'WS SUP' => 'Workshop Supervisor',
    'BOM' || 'BRANCH OPERATIONS MANAGER' => 'Branch Operations Manager',
    'ADMIN' ||
    'ADMINISTRATOR' ||
    'COMPLIANCE ADMINISTRATOR' => 'Compliance Administrator',
    'GM' || 'GENERAL MANAGER' => 'General Manager',
    '5S_UTILITIES' ||
    '5S UTILITIES' ||
    '5S-UTILITIES' ||
    'UTILITIES' ||
    'UTILITY' ||
    'RESTROOM' => '5S Utilities',
    '5S_SERVICE' ||
    '5S SERVICE' ||
    '5S-SERVICE' ||
    'SERVICE_5S' ||
    'SERVICE 5S' => '5S Service',
    '5S_SALES' ||
    '5S SALES' ||
    '5S-SALES' ||
    'SALES_5S' ||
    'SALES 5S' => '5S Sales',
    'SALES_SERVICE' ||
    'SALES-SERVICE' ||
    'SALES & SERVICE' ||
    '5S' => '5S Inspector',
    _ => canonicalUserType.isEmpty ? 'Gateway User' : canonicalUserType,
  };

  bool get isSalesManager => switch (userType.trim().toUpperCase()) {
    'SM' || 'SALES MANAGER' || 'SALES_MANAGER' || 'SALES MGR' => true,
    _ => false,
  };

  bool get isAftersalesManager => switch (userType.trim().toUpperCase()) {
    'ASM' || 'AFTERSALES MANAGER' || 'AFTERSALES_MANAGER' || 'AS MGR' => true,
    _ => false,
  };

  bool get isAftersalesChecker => switch (canonicalUserType.toUpperCase()) {
    'ASM' ||
    'AFTERSALES MANAGER' ||
    'AFTERSALES_MANAGER' ||
    'AS MGR' ||
    'CE SERVICE' ||
    'CE_SERVICE' ||
    'CE' ||
    'JC' ||
    'JOB CONTROLLER' ||
    'JOB_CONTROLLER' ||
    'PARTS' ||
    'PARTS SUPERVISOR' ||
    'PARTS_SUPERVISOR' ||
    'WS SUP' => true,
    _ => false,
  };

  bool get isDosAuditor {
    final type = userType.trim().toUpperCase();
    return isDosSales || isDosAftersales || type == 'DOS';
  }

  bool get isPic => switch (userType.trim().toUpperCase()) {
    'PIC' || 'PERSON IN CHARGE' => false,
    _ => false,
  };

  bool get isAdmin => switch (userType.trim().toUpperCase()) {
    'ADMIN' ||
    'ADMINISTRATOR' ||
    'COMPLIANCE ADMINISTRATOR' ||
    'GM' ||
    'GENERAL MANAGER' ||
    'BOM' ||
    'BRANCH OPERATIONS MANAGER' => true,
    _ => false,
  };

  /// Returns true if the user is assigned to 5S Utilities inspection.
  bool get is5sUtilities {
    if (isDosAuditor || isAdmin) return false;

    final type = userType.trim().toUpperCase();
    if (type == '5S_UTILITIES' ||
        type == '5S UTILITIES' ||
        type == '5S-UTILITIES' ||
        type == 'UTILITIES' ||
        type == 'UTILITY' ||
        type == 'RESTROOM') {
      return true;
    }

    final assignment = (picAssignmentType ?? '').trim().toLowerCase();
    if (assignment == 'utilities' ||
        assignment == 'utility' ||
        assignment == 'restroom') {
      return true;
    }

    final label = (picAssignmentLabel ?? '').trim().toLowerCase();
    if (label.contains('utilit') || label.contains('restroom')) {
      return true;
    }

    return false;
  }

  /// Alias for is5sUtilities to maintain compatibility
  bool get isUtilities => is5sUtilities;

  /// Returns true if the user is assigned to 5S Service inspection.
  bool get is5sService {
    if (isDosAuditor || isAdmin || is5sUtilities) return false;

    final type = userType.trim().toUpperCase();
    if (type == '5S_SERVICE' ||
        type == '5S SERVICE' ||
        type == '5S-SERVICE' ||
        type == 'SERVICE_5S' ||
        type == 'SERVICE 5S') {
      return true;
    }

    final assignment = (picAssignmentType ?? '').trim().toLowerCase();
    if (assignment == 'service' || assignment == '5s_service') {
      return true;
    }

    final label = (picAssignmentLabel ?? '').trim().toLowerCase();
    if (label.contains('service') && !label.contains('sales')) {
      return true;
    }

    return false;
  }

  /// Returns true if the user is assigned to 5S Sales inspection.
  bool get is5sSales {
    if (isDosAuditor || isAdmin || is5sUtilities) return false;

    final type = userType.trim().toUpperCase();
    if (type == '5S_SALES' ||
        type == '5S SALES' ||
        type == '5S-SALES' ||
        type == 'SALES_5S' ||
        type == 'SALES 5S') {
      return true;
    }

    final assignment = (picAssignmentType ?? '').trim().toLowerCase();
    if (assignment == 'sales' || assignment == '5s_sales') {
      return true;
    }

    final label = (picAssignmentLabel ?? '').trim().toLowerCase();
    if (label.contains('sales') && !label.contains('service')) {
      return true;
    }

    return false;
  }

  /// Legacy combined 5S getter; returns false for cleanly separated roles.
  bool get isSalesService5s {
    if (isDosAuditor || isAdmin || is5sUtilities || is5sSales || is5sService) {
      return false;
    }
    final type = userType.trim().toUpperCase();
    if (type == 'SALES_SERVICE' ||
        type == 'SALES-SERVICE' ||
        type == 'SALES & SERVICE' ||
        type == '5S') {
      return true;
    }

    final assignment = (picAssignmentType ?? '').trim().toLowerCase();
    if (assignment == 'sales_service' ||
        assignment == 'sales-service' ||
        assignment == 'sales_and_service') {
      return true;
    }

    return false;
  }

  /// Returns true if the user is strictly scoped to DOS Sales.
  bool get isDosSales {
    if (isSalesManager) return true;
    final type = userType.trim().toUpperCase();
    if (type == 'DOS_SALES' || type == 'DOS-SALES' || type == 'DOS SALES') {
      return true;
    }
    return false;
  }

  /// Returns true if the user is strictly scoped to DOS Aftersales.
  bool get isDosAftersales {
    if (isAftersalesChecker) return true;
    final type = userType.trim().toUpperCase();
    if (type == 'DOS_AFTERSALES' ||
        type == 'DOS-AFTERSALES' ||
        type == 'DOS AFTERSALES') {
      return true;
    }
    return false;
  }

  /// Returns true if the user has multi-track DOS access (Admin or unconstrained DOS auditor).
  bool get canSwitchDosTracks {
    if (isAdmin) return true;
    if (isSalesManager ||
        isAftersalesChecker ||
        isDosSales ||
        isDosAftersales) {
      return false;
    }
    final type = userType.trim().toUpperCase();
    if (type == 'DOS') return true;
    return false;
  }

  String? get dosCheckerCode => switch (canonicalUserType.toUpperCase()) {
    'SM' ||
    'SALES MANAGER' ||
    'SALES_MANAGER' ||
    'SALES MGR' ||
    'DOS_SALES' ||
    'DOS-SALES' ||
    'DOS SALES' => 'SALES MANAGER',
    'ASM' || 'AFTERSALES MANAGER' || 'AFTERSALES_MANAGER' || 'AS MGR' => 'ASM',
    'CE SERVICE' || 'CE_SERVICE' || 'CE' => 'CE SERVICE',
    'JC' || 'JOB CONTROLLER' || 'JOB_CONTROLLER' => 'JC',
    'PARTS SUPERVISOR' || 'PARTS_SUPERVISOR' || 'PARTS' => 'PARTS',
    'WS SUP' => 'WS SUP',
    _ => null,
  };

  bool get canAccessSubform =>
      isAdmin ||
      isAftersalesManager ||
      dosCheckerCode == 'CE SERVICE' ||
      dosCheckerCode == 'WS SUP' ||
      dosCheckerCode == 'ASM';

  bool get canAccessDocumentation => isAdmin || dosCheckerCode == 'CE SERVICE';

  bool matchesCheckerRole(String? itemChecker) {
    if (itemChecker == null) return false;
    if (isAdmin) return true;
    if (isDosAftersales && dosCheckerCode == null) return true;

    final roleChecker = dosCheckerCode;
    if (roleChecker != null) {
      final canonicalItem = canonicalDosChecker(itemChecker);
      return canonicalItem == roleChecker;
    }

    return normalizeUserType(itemChecker).toUpperCase() ==
        canonicalUserType.toUpperCase();
  }

  String get assignmentLabel {
    final label = picAssignmentLabel?.trim();
    if (label != null && label.isNotEmpty) return label;

    return switch (picAssignmentType?.trim().toLowerCase()) {
      'utilities' => '5S Utilities',
      'service' => '5S Service',
      'sales' => '5S Sales',
      'sales_service' || 'sales-service' => 'Sales & Service',
      _ => roleLabel,
    };
  }

  /// User's name with any trailing parenthetical role annotations removed
  /// (e.g. "Marcus Sales (Sales Manager)" -> "Marcus Sales").
  String get displayName {
    final stripped = name.replaceFirst(RegExp(r'(\s*\([^)]*\))+$'), '').trim();
    return stripped.isNotEmpty ? stripped : name.trim();
  }

  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'GU';
    if (words.length == 1) {
      final word = words.single;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  factory AuthenticatedUser.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Laravel returned invalid profile data.');
    }
    final data = <String, dynamic>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    final id = data['id'];
    final name = data['name'];
    final email = data['email'];
    final userType = data['user_type'];
    if (id is! num ||
        name is! String ||
        email is! String ||
        userType is! String) {
      throw const FormatException('Laravel returned invalid profile data.');
    }

    String? optionalString(String key) {
      final raw = data[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw FormatException('Laravel returned an invalid $key.');
      }
      final normalized = raw.trim();
      return normalized.isEmpty ? null : normalized;
    }

    return AuthenticatedUser(
      id: id.toInt(),
      name: name.trim(),
      email: email.trim(),
      branch: optionalString('branch'),
      userType: normalizeUserType(userType),
      picAssignmentType: optionalString('pic_assignment_type'),
      picAssignmentLabel: optionalString('pic_assignment_label'),
      accountStatus: optionalString('account_status') ?? 'active',
      avatarUrl: optionalString('avatar_url'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'branch': branch,
    'user_type': canonicalUserType,
    'pic_assignment_type': picAssignmentType,
    'pic_assignment_label': picAssignmentLabel,
    'account_status': accountStatus,
    'avatar_url': avatarUrl,
  };
}

String? canonicalDosChecker(String? checker) {
  if (checker == null) return null;

  final normalized = normalizeUserType(checker)
      .trim()
      .toUpperCase()
      .replaceAll('_', ' ')
      .replaceAll('.', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  return switch (normalized) {
    'SM' || 'SALES MANAGER' || 'SALES MGR' => 'SALES MANAGER',
    'ASM' || 'AFTERSALES MANAGER' || 'AS MGR' => 'ASM',
    'CE' ||
    'CE SERVICE' ||
    'CUSTOMER EXPERIENCE SERVICE' ||
    'CUSTOMER EXPERIENCE (CE) SERVICE' => 'CE SERVICE',
    'JC' || 'JOB CONTROLLER' => 'JC',
    'PARTS' ||
    'PART SUPERVISOR' ||
    'PARTS SUPERVISOR' ||
    'PART SUPERVISOR/ANALYS' ||
    'PARTS SUPERVISOR/ANALYS' ||
    'PART SUPERVISOR/ANALYST' ||
    'PARTS SUPERVISOR/ANALYST' => 'PARTS',
    'WS SUP' => 'WS SUP',
    _ => normalized,
  };
}
