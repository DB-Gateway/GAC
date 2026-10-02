class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.unread,
    required this.data,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool unread;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUtilitiesInspectionNotice => const {
    'utilities_due_soon',
    'utilities_due_now',
    'utilities_inspection_missed',
  }.contains(type);

  factory UserNotification.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Server returned an invalid notification.');
    }
    final json = <String, dynamic>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    final id = json['id'];
    final type = json['type'];
    final title = json['title'];
    final message = json['message'];
    final unread = json['unread'];
    if (id is! String ||
        type is! String ||
        title is! String ||
        message is! String ||
        unread is! bool) {
      throw const FormatException('Server returned an invalid notification.');
    }

    DateTime? date(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw FormatException('Server returned an invalid $key.');
      }
      return DateTime.tryParse(raw)?.toLocal();
    }

    final rawData = json['data'];
    return UserNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      unread: unread,
      data: rawData is Map
          ? {
              for (final entry in rawData.entries)
                if (entry.key is String) entry.key as String: entry.value,
            }
          : const {},
      readAt: date('read_at'),
      createdAt: date('created_at'),
    );
  }

  UserNotification markRead({DateTime? at}) => UserNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    unread: false,
    data: data,
    readAt: at ?? DateTime.now(),
    createdAt: createdAt,
  );

  /// Returns whether this notification originated from or relates to a
  /// Branch Operations Manager (BOM) or General Manager (GM).
  bool get isFromBomOrGm {
    if (type == 'finding_escalated') return true;
    final typeLower = type.toLowerCase();
    final titleLower = title.toLowerCase();
    final messageLower = message.toLowerCase();

    // Direct checklist draft reminder from manager/BOM
    if (type == 'checklist_draft_reminder') return true;

    // Type contains BOM or GM or manager
    if (typeLower.contains('bom') ||
        typeLower.contains('gm') ||
        typeLower.contains('branch_operations_manager') ||
        typeLower.contains('general_manager') ||
        typeLower.contains('manager_reminder')) {
      return true;
    }

    // Title mentions BOM or GM
    if (titleLower.contains('bom') ||
        titleLower.contains('gm') ||
        titleLower.contains('branch operations manager') ||
        titleLower.contains('general manager')) {
      return true;
    }

    // Message mentions BOM or GM
    if (messageLower.contains('bom') ||
        messageLower.contains('gm') ||
        messageLower.contains('branch operations manager') ||
        messageLower.contains('general manager') ||
        messageLower.contains('operations manager')) {
      return true;
    }

    // Metadata payload fields indicating BOM or GM sender
    final senderRole = data['sender_role']?.toString().toLowerCase() ?? '';
    final senderType = data['sender_type']?.toString().toLowerCase() ?? '';
    final senderName = data['sender_name']?.toString().toLowerCase() ?? '';
    if (senderRole.contains('bom') ||
        senderRole.contains('gm') ||
        senderRole.contains('manager') ||
        senderType.contains('bom') ||
        senderType.contains('gm') ||
        senderName.contains('bom') ||
        senderName.contains('gm')) {
      return true;
    }

    return false;
  }

  /// Returns whether this notification is an escalation or follow-up notice.
  bool get isFollowUp {
    final typeLower = type.toLowerCase();
    final eventLower = (data['event']?.toString() ?? '').toLowerCase();
    return typeLower == 'finding_escalated' ||
        typeLower.contains('follow_up') ||
        typeLower.contains('escalat') ||
        eventLower.contains('follow_up') ||
        eventLower.contains('escalat');
  }

  /// Returns whether this notification is a general notice (e.g. reminder, alert, announcement).
  bool get isNotice => !isFollowUp;

  /// Returns whether a follow-up action has already been submitted/completed for this notification.
  bool get isFollowedUp {
    return data['has_follow_up'] == true ||
        data['follow_up_submitted_at'] != null ||
        (data['follow_up_report_id'] != null &&
            data['follow_up_report_id'] != 0);
  }
}

class NotificationInbox {
  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });

  final List<UserNotification> notifications;
  final int unreadCount;
}
