import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/models/escalation_follow_up.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/services/escalation_follow_up_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notice = UserNotification(
  id: 'abc-123',
  type: 'finding_escalated',
  title: '',
  message: '',
  unread: true,
  data: {'recipient_user_id': 7},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      gacAuthTokenKey: 'interactive-token',
      gacNotificationTokenKey: 'read-only-token',
      gacPreviousUserIdKey: '7',
    }),
  );

  test(
    'uploads photos and custom remarks using the interactive credential',
    () async {
      final service = EscalationFollowUpApiService(
        apiUrl: 'https://test.local/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/notifications/abc-123/follow-ups');
          expect(request.headers['Authorization'], 'Bearer interactive-token');
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data;'),
          );
          final body = utf8.decode(request.bodyBytes);
          expect(body, contains('name="remark_option"\r\n\r\nothers'));
          expect(
            body,
            contains('name="remarks"\r\n\r\nSupplier visit arranged.'),
          );
          expect(body, contains('name="photos[]"; filename="photo.jpg"'));
          return _success();
        }),
      );
      addTearDown(service.dispose);
      final result = await service.submit(
        notification: _notice,
        requestId: 'a' * 32,
        remark: EscalationRemark.others,
        otherRemarks: '  Supplier visit arranged.  ',
        photos: [
          FollowUpPhoto(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'photo.jpg',
          ),
        ],
      );
      expect(result.recipientName, 'Brenda BOM');
    },
  );

  test('preset requests omit custom remarks and optional photos', () async {
    final service = EscalationFollowUpApiService(
      client: MockClient((request) async {
        final body = utf8.decode(request.bodyBytes);
        expect(body, contains('in_progress'));
        expect(body, isNot(contains('name="remarks"')));
        expect(body, isNot(contains('photos[]')));
        return _success();
      }),
    );
    addTearDown(service.dispose);
    await service.submit(
      notification: _notice,
      requestId: 'a' * 32,
      remark: EscalationRemark.inProgress,
      otherRemarks: 'Stale custom text',
      photos: [],
    );
  });

  test(
    'read-only device credentials cannot submit after interactive timeout',
    () async {
      SharedPreferences.setMockInitialValues({
        gacNotificationTokenKey: 'read-only-token',
        gacPreviousAuthTokenKey: 'old-token',
      });
      final service = EscalationFollowUpApiService(
        client: MockClient((_) async {
          fail('No request should be made.');
        }),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.submit(
          notification: _notice,
          requestId: 'a' * 32,
          remark: EscalationRemark.inProgress,
          otherRemarks: '',
          photos: [],
        ),
        throwsA(
          isA<EscalationFollowUpException>().having(
            (e) => e.message,
            'message',
            contains('Sign in again'),
          ),
        ),
      );
    },
  );

  test(
    'server validation failures are shown instead of reporting success',
    () async {
      final service = EscalationFollowUpApiService(
        client: MockClient(
          (_) async => http.Response(
            '{"message":"This finding is no longer assigned to your account."}',
            403,
          ),
        ),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.submit(
          notification: _notice,
          requestId: 'a' * 32,
          remark: EscalationRemark.inProgress,
          otherRemarks: '',
          photos: [],
        ),
        throwsA(
          isA<EscalationFollowUpException>().having(
            (e) => e.message,
            'message',
            contains('no longer assigned'),
          ),
        ),
      );
    },
  );
}

http.Response _success() => http.Response(
  jsonEncode({
    'follow_up': {
      'id': 1,
      'remarks': 'Update',
      'recipient_name': 'Brenda BOM',
      'created_at': '2026-09-14T09:00:00Z',
    },
  }),
  201,
);
