import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/escalation_follow_up.dart';
import '../models/user_notification.dart';

const maxFollowUpPhotos = 3;
const maxFollowUpPhotoBytes = 10 * 1024 * 1024;
const maxFollowUpRemarksLength = 2000;

abstract interface class EscalationFollowUpRepository {
  Future<EscalationFollowUp> submit({
    required UserNotification notification,
    required String requestId,
    required EscalationRemark remark,
    required String otherRemarks,
    required List<FollowUpPhoto> photos,
  });
}

class EscalationFollowUpApiService implements EscalationFollowUpRepository {
  EscalationFollowUpApiService({http.Client? client, this.apiUrl = gacApiUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String apiUrl;

  void dispose() => _client.close();

  @override
  Future<EscalationFollowUp> submit({
    required UserNotification notification,
    required String requestId,
    required EscalationRemark remark,
    required String otherRemarks,
    required List<FollowUpPhoto> photos,
  }) async {
    final remarks = otherRemarks.trim();
    if (remark == EscalationRemark.others &&
        (remarks.isEmpty || remarks.length > maxFollowUpRemarksLength)) {
      throw const EscalationFollowUpException('Enter your follow-up remarks.');
    }
    if (photos.length > maxFollowUpPhotos ||
        photos.any(
          (photo) =>
              photo.bytes.isEmpty || photo.bytes.length > maxFollowUpPhotoBytes,
        )) {
      throw const EscalationFollowUpException(
        'Attach up to 3 photos, no larger than 10 MB each.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    // The long-lived notification credential only permits reading the inbox.
    final token = preferences.getString(gacAuthTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const EscalationFollowUpException(
        'Sign in again to send a follow-up.',
      );
    }
    final recipientId = notification.data['recipient_user_id']?.toString();
    final accountId = preferences.getString(gacPreviousUserIdKey);
    if (recipientId != null && accountId != null && recipientId != accountId) {
      throw const EscalationFollowUpException(
        'This escalation belongs to a different account.',
      );
    }

    final base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(
              '$base/notifications/${Uri.encodeComponent(notification.id)}/follow-ups',
            ),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          ..fields.addAll({
            'request_id': requestId,
            'remark_option': remark.code,
          });
    if (remark == EscalationRemark.others) request.fields['remarks'] = remarks;
    for (final photo in photos) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photos[]',
          photo.bytes,
          filename: photo.filename,
        ),
      );
    }

    late final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const EscalationFollowUpException(
        'Could not send the follow-up. Check your connection and try again.',
      );
    }
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map ? decoded : const {};
    if (response.statusCode == 401) {
      throw const EscalationFollowUpException(
        'Sign in again to send a follow-up.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EscalationFollowUpException(
        data['message'] is String
            ? data['message'] as String
            : 'The follow-up could not be saved. Please try again.',
      );
    }
    await preferences.reload();
    if (preferences.getString(gacAuthTokenKey) != token) {
      throw const EscalationFollowUpException(
        'Your sign-in changed. Reopen this escalation to check the follow-up.',
      );
    }
    try {
      return EscalationFollowUp.fromJson(data['follow_up']);
    } on FormatException catch (error) {
      throw EscalationFollowUpException(error.message);
    }
  }
}

class EscalationFollowUpException implements Exception {
  const EscalationFollowUpException(this.message);
  final String message;
}
