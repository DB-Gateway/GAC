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

  factory UserNotification.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Laravel returned an invalid notification.');
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
      throw const FormatException('Laravel returned an invalid notification.');
    }

    DateTime? date(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw FormatException('Laravel returned an invalid $key.');
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
}

class NotificationInbox {
  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });

  final List<UserNotification> notifications;
  final int unreadCount;
}
