import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/services/profile_service.dart';

const _profileJson = {
  'id': 7,
  'name': 'Jamie Cruz',
  'email': 'jamie@gateway.local',
  'branch': 'Makati',
  'user_type': 'PIC',
  'pic_assignment_type': 'utilities',
  'pic_assignment_label': 'Utilities',
  'account_status': 'active',
  'avatar_url': '/storage/avatars/7/photo.png',
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {
      gacAuthTokenKey: 'mobile-token',
    });
  });

  test('fetches the authenticated profile and refreshes its cache', () async {
    late http.Request captured;
    final service = ProfileApiService(
      apiUrl: 'https://gateway.test/api',
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'user': _profileJson}), 200);
      }),
    );

    final profile = await service.fetchProfile();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/profile');
    expect(captured.headers['Authorization'], 'Bearer mobile-token');
    expect(profile.name, 'Jamie Cruz');
    expect(profile.initials, 'JC');
    expect(profile.assignmentLabel, 'Utilities');
    final preferences = await SharedPreferences.getInstance();
    expect(
      jsonDecode(preferences.getString(gacAuthUserKey)!)['avatar_url'],
      '/storage/avatars/7/photo.png',
    );
  });

  test('updates only editable information and remembered email', () async {
    SharedPreferences.setMockInitialValues(const {
      gacAuthTokenKey: 'mobile-token',
      'gac_remember_me': true,
    });
    late http.Request captured;
    final service = ProfileApiService(
      apiUrl: 'https://gateway.test/api',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'user': {
              ..._profileJson,
              'name': 'Jamie Updated',
              'email': 'updated@gateway.local',
            },
          }),
          200,
        );
      }),
    );

    final profile = await service.updateProfile(
      name: ' Jamie Updated ',
      email: ' UPDATED@GATEWAY.LOCAL ',
    );

    expect(captured.method, 'PATCH');
    expect(jsonDecode(captured.body), {
      'name': 'Jamie Updated',
      'email': 'updated@gateway.local',
    });
    expect(profile.email, 'updated@gateway.local');
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('gac_remember_email'),
      'updated@gateway.local',
    );
  });

  test('surfaces Laravel password validation messages', () async {
    final service = ProfileApiService(
      apiUrl: 'https://gateway.test/api',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'current_password': ['The current password is incorrect.'],
            },
          }),
          422,
        ),
      ),
    );

    await expectLater(
      service.changePassword(
        currentPassword: 'wrong-password',
        password: 'new-password',
        passwordConfirmation: 'new-password',
      ),
      throwsA(
        isA<ProfileApiException>()
            .having((error) => error.status, 'status', 422)
            .having(
              (error) => error.message,
              'message',
              'The current password is incorrect.',
            ),
      ),
    );
  });

  test('uploads a multipart avatar and parses the updated user', () async {
    final client = _MultipartClient();
    final service = ProfileApiService(
      apiUrl: 'https://gateway.test/api',
      client: client,
    );

    final profile = await service.uploadAvatar(
      bytes: const [137, 80, 78, 71],
      filename: 'profile.png',
    );

    final request = client.request! as http.MultipartRequest;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/profile/avatar');
    expect(request.headers['Authorization'], 'Bearer mobile-token');
    expect(request.files.single.field, 'avatar');
    expect(request.files.single.filename, 'profile.png');
    expect(profile.avatarUrl, '/storage/avatars/7/photo.png');
  });

  test('sign out clears the local session after revoking the token', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(gacAuthUserKey, jsonEncode(_profileJson));
    final service = ProfileApiService(
      apiUrl: 'https://gateway.test/api',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/logout');
        return http.Response('{}', 200);
      }),
    );

    await service.logout();

    expect(preferences.getString(gacAuthTokenKey), isNull);
    expect(preferences.getString(gacAuthUserKey), isNull);
  });
}

class _MultipartClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode({'user': _profileJson}))),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}
