const String gacApiUrl = String.fromEnvironment(
  'GAC_API_URL',
  defaultValue: String.fromEnvironment(
    'EXPO_PUBLIC_API_URL',
    defaultValue: 'http://10.0.20.100:8000/api',
  ),
);

const String gacAuthTokenKey = 'gac_auth_token';
const String gacAuthUserKey = 'gac_auth_user';
const String gacRememberMeKey = 'gac_remember_me';
const String gacRememberEmailKey = 'gac_remember_email';
const String gacPreviousUserTypeKey = 'gac_previous_user_type';
const String gacPreviousAssignmentKey = 'gac_previous_user_assignment';
const String gacPreviousAssignmentLabelKey =
    'gac_previous_user_assignment_label';
const String gacPreviousAuthTokenKey = 'gac_previous_auth_token';
const String gacNotificationTokenKey = 'gac_notification_token';
const String gacNotificationDeviceIdKey = 'gac_notification_device_id';
const String gacPreviousUserIdKey = 'gac_previous_user_id';
const String gacPreviousRememberMeKey = 'gac_previous_remember_me';
const String gacPreviousBranchKey = 'gac_previous_user_branch';
const String gacPendingNotificationPayloadKey =
    'gac_pending_notification_payload';
const String gacSecurityPinKey = 'gac_security_pin';
const String gacBiometricsEnabledKey = 'gac_biometrics_enabled';
const String gacSessionLastActivityKey = 'gac_session_last_activity';
const String gacReminderLeadTimeKey = 'gac_reminder_lead_time_minutes';
const String gacCachedChecklistCatalogKey = 'gac_cached_checklist_catalog';

/// Local checklist data is for deliberate offline/demo builds only. Keeping it
/// disabled prevents an API failure from looking like a connected checklist
/// that will later fail when the user tries to submit it to Server.
const bool gacEnableOfflineChecklistFallback = bool.fromEnvironment(
  'GAC_ENABLE_OFFLINE_CHECKLIST_FALLBACK',
  defaultValue: false,
);

/// Default lead time before a task's due time to fire the reminder.
const int gacDefaultReminderLeadTimeMinutes = 5;

/// Duration of inactivity before a non-remembered session times out.
const Duration gacSessionTimeoutDuration = Duration(minutes: 15);

/// Time zone used by Gateway's checklist windows and hourly inspection slots.
const String gacBusinessTimezone = String.fromEnvironment(
  'GAC_BUSINESS_TIMEZONE',
  defaultValue: 'Asia/Manila',
);

String? resolveGacAssetUrl(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  final assetUri = Uri.tryParse(normalized);
  if (assetUri != null && assetUri.hasScheme) return assetUri.toString();

  final apiUri = Uri.tryParse(gacApiUrl);
  if (apiUri == null || !apiUri.hasScheme || apiUri.host.isEmpty) {
    return normalized;
  }

  final origin = Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
  );
  final path = normalized.startsWith('/') ? normalized : '/$normalized';
  return origin.replace(path: path).toString();
}
