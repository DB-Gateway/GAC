import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../config/api_config.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

const _inboxWorkName = 'gac-device-inbox';

Future<String> notificationDeviceId() async {
  final preferences = await SharedPreferences.getInstance();
  final stored = preferences.getString(gacNotificationDeviceIdKey);
  if (stored != null) return stored;
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final id =
      '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  await preferences.setString(gacNotificationDeviceIdKey, id);
  return id;
}

@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != _inboxWorkName) return true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    if (preferences.getString(gacNotificationTokenKey) == null ||
        !(preferences.getBool(gacPushNotificationsEnabledKey) ?? true)) {
      return true;
    }
    try {
      await LocalNotificationService.instance.initialize();
      final inbox = await NotificationApiService().fetchNotifications();
      await LocalNotificationService.instance.showUnreadInboxNotifications(
        inbox.notifications,
      );
      return true;
    } on NotificationApiException catch (error) {
      // Revoked or disabled accounts wait for the next successful login.
      return error.status == 401 || error.status == 403;
    } catch (_) {
      return false;
    }
  });
}

Future<void> startBackgroundNotificationPolling() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await Workmanager().initialize(notificationBackgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _inboxWorkName,
      _inboxWorkName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (_) {
    // The foreground inbox remains available if Android cannot schedule work.
  }
}
