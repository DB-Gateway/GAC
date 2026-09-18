import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/services/checklist_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catalog request sends Sanctum token and parses database templates',
    () async {
      SharedPreferences.setMockInitialValues({gacAuthTokenKey: 'mobile-token'});
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.toString(),
          'http://server.test/api/checklists?date=2026-08-29',
        );
        expect(request.headers['Authorization'], 'Bearer mobile-token');
        return http.Response(
          jsonEncode({
            'date': '2026-08-29',
            'branch': 'Pasong Tamo',
            'checklists': [
              {
                'id': 1,
                'slug': 'gateway-5s',
                'name': 'Admin Updated 5S',
                'description': 'Live from checklist_templates.',
                'version': 7,
                'settings': {'validation_mode': 'yes_no_na'},
                'section_count': 9,
                'item_count': 56,
                'work_unit_count': 56,
                'submission': null,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = ChecklistApiService(
        client: client,
        apiUrl: 'http://server.test/api',
      );

      final result = await service.fetchCatalog(date: '2026-08-29');

      expect(result, hasLength(1));
      expect(result.single.name, 'Admin Updated 5S');
      expect(result.single.version, 7);
      expect(result.single.itemCount, 56);
      expect(result.single.totalWorkUnits, 56);
    },
  );

  test('draft request sends client time as an absolute UTC instant', () async {
    SharedPreferences.setMockInitialValues({gacAuthTokenKey: 'mobile-token'});
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'http://server.test/api/checklists/restroom/draft',
      );

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final clientTime = body['client_time'] as String;
      expect(clientTime, endsWith('Z'));
      expect(DateTime.parse(clientTime).isUtc, isTrue);
      expect(body['client_timezone'], gacBusinessTimezone);
      expect((body['context'] as Map<String, dynamic>)['draft_position'], {'item_key': 'item-2', 'slot_key': '08:00'});
      expect(
        (body['context'] as Map<String, dynamic>)['client_time'],
        clientTime,
      );
      expect(request.headers['X-Client-Time'], clientTime);
      expect(request.headers['X-Client-Timezone'], gacBusinessTimezone);

      return http.Response(
        jsonEncode({
          'submission': {
            'id': 10,
            'status': 'draft',
            'audit_date': '2026-09-10',
            'template_version': 2,
            'scores': {},
            'responses': {},
            'answered_items': 0,
            'total_items': 1,
            'completion_percentage': 0,
            'submitted_at': null,
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ChecklistApiService(
      client: client,
      apiUrl: 'http://Server.test/api',
    );

    final result = await service.saveDraft(
      'restroom',
      date: '2026-09-10',
      responses: const [],
      context: const {'draft_position': {'item_key': 'item-2', 'slot_key': '08:00'}},
    );

    expect(result.status, 'draft');
  });
}
