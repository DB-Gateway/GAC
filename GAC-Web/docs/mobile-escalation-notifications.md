# Mobile escalation notifications

When a BOM saves a NO finding's Escalate To, Action Plan, and Commitment Date, the server stores a `finding_escalated` database notification for the owner (`checklist_submissions.user_id`) of that submission. The owner must still have an active account, belong to the submission's branch, and have access to its checklist. Other auditors who share the same checklist role do not receive that submission's alert. The department selected in Escalate To is shown as part of the instruction; it is not used to broadcast to unrelated accounts.

The notification snapshots the checklist, question, finding, branch, audit date, escalation recipient, commitment date, action plan, and BOM name. Identical saves do not send another notification. Changed instructions create a new notification. Finding edits and their notifications are written in the same database transaction.

## App update

Rebuild/install the Flutter app in `../GAC` and sign in once after updating both projects. No new database migration is needed; device credentials use the existing Sanctum token table. The standalone `gac-api/login.php` does not issue the app's Laravel API tokens and is not used by this integration.

Each app installation generates a random device UUID. Successful `/api/login` requests supply `notification_device_id` and receive a separate `notification_token`. The token grants access only to `/api/device-notifications` and its read-status routes. It deliberately continues after the interactive token expires or is logged out. Inactive accounts and revoked device tokens are rejected. It cannot authenticate checklist, profile, or management API requests.

The app remembers the user's ID and the notification credential independently of Remember Me. A new login on that installation revokes its previous notification credential and replaces the recipient. Other installations are preserved. On account changes, the app clears the previous notification payloads and displayed alerts. Scheduled role reminders continue to follow the last user.

Tapping an escalation in the app inbox or Android notification tray opens a scrollable details modal. A system notification can open that modal after timeout using only the notification credential; it does not restore an authenticated checklist session. Taps for a different remembered user are ignored. Opening the details marks the notification as read. The inbox's snapshot can still be opened if marking read temporarily fails.

## Delivery timing

The active inbox checks every 15 seconds. After inactivity timeout, the running app checks the remembered inbox every 45 seconds regardless of Remember Me or Utilities assignment. Android WorkManager also checks the same server inbox with a network constraint on a 15-minute periodic schedule, including after the app process exits. Actual background runs can be delayed by Android battery management. This is background polling, not instant FCM push. Android force-stop, disabled notification permissions, or no network prevents delivery until the app/device can run again. See the [Workmanager API](https://pub.dev/documentation/workmanager/latest/workmanager/Workmanager-class.html).

Enable the app's notification setting and Android notification permission. For a physical phone, build with `--dart-define=GAC_API_URL=https://your-server/api`; the default `10.0.2.2:8000` address is for the Android emulator. Older app/server combinations use the existing API-token fallback until the next upgraded sign-in; that fallback cannot survive server-side revocation/expiry.

## Verification

- Server: `php artisan test --compact --filter="DashboardFindingEscalationTest|MobileNotificationDeviceTest|MobileChecklistApiTest"`
- App: `flutter test test/escalation_notification_test.dart test/notification_service_test.dart test/local_notification_service_test.dart test/bom_gm_notification_timeout_test.dart test/draft_reminder_notification_test.dart test/user_notifications_recent_history_test.dart`
- App analysis/build: `flutter analyze --no-pub` and `flutter build apk --debug`

For a device acceptance check, sign in as an assigned auditor without Remember Me, let the session time out, then save a complete escalation for that auditor's submission from the BOM dashboard. Tap the alert and verify the modal fields. Repeat after signing into the same device as another auditor; only the new account's notifications should arrive. Closed-app notification timing must be checked on the target device because Android schedules background work.
