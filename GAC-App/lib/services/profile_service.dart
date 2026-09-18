import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart';

abstract interface class ProfileRepository {
  Future<AuthenticatedUser?> loadCachedProfile();

  Future<AuthenticatedUser> fetchProfile();

  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  });

  Future<AuthenticatedUser> deleteAvatar();

  Future<void> logout();
}

class ProfileApiService implements ProfileRepository {
  ProfileApiService({
    http.Client? client,
    this.apiUrl = gacApiUrl,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _client = client ?? http.Client(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final http.Client _client;
  final String apiUrl;
  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<AuthenticatedUser?> loadCachedProfile() async {
    final preferences = await _preferencesLoader();
    final encoded = preferences.getString(gacAuthUserKey);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return AuthenticatedUser.fromJson(jsonDecode(encoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthenticatedUser> fetchProfile() async {
    final data = await _jsonRequest('GET', '/profile');
    return _profileFromResponse(data);
  }

  @override
  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  }) async {
    final data = await _jsonRequest(
      'PATCH',
      '/profile',
      body: {'name': name.trim(), 'email': email.trim().toLowerCase()},
    );
    return _profileFromResponse(data);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _jsonRequest(
      'PUT',
      '/profile/password',
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    if (data['user'] is Map) {
      await _profileFromResponse(data);
    }
  }

  @override
  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final preferences = await _preferencesLoader();
    final token = _requireToken(preferences);
    final uri = _uri('/profile/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..files.add(
        http.MultipartFile.fromBytes('avatar', bytes, filename: filename),
      );

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
    } catch (_) {
      throw ProfileApiException(
        'Cannot reach Server at ${_baseUrl()}. Check your connection.',
      );
    }
    final data = _decodeResponse(response);
    _throwForResponse(
      response,
      data,
      fallback: 'The photo could not be saved.',
    );
    return _profileFromResponse(data);
  }

  @override
  Future<AuthenticatedUser> deleteAvatar() async {
    final data = await _jsonRequest('DELETE', '/profile/avatar');
    return _profileFromResponse(data);
  }

  @override
  Future<void> logout() async {
    final preferences = await _preferencesLoader();
    try {
      final token = preferences.getString(gacAuthTokenKey);
      if (token != null && token.isNotEmpty) {
        final request = http.Request('POST', _uri('/logout'))
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          });
        await _client.send(request).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Local sign-out must still complete when the API is unavailable.
    } finally {
      await preferences.remove(gacAuthTokenKey);
      await preferences.remove(gacAuthUserKey);
    }
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final preferences = await _preferencesLoader();
    final token = _requireToken(preferences);
    final request = http.Request(method, _uri(endpoint))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } catch (_) {
      throw ProfileApiException(
        'Cannot reach Server at ${_baseUrl()}. Check your connection.',
      );
    }
    final data = _decodeResponse(response);
    _throwForResponse(response, data, fallback: 'The profile request failed.');
    return data;
  }

  Future<AuthenticatedUser> _profileFromResponse(
    Map<String, dynamic> data,
  ) async {
    final profile = AuthenticatedUser.fromJson(data['user']);
    await _cacheProfile(profile);
    return profile;
  }

  Future<void> _cacheProfile(AuthenticatedUser profile) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(gacAuthUserKey, jsonEncode(profile.toJson()));

    if (preferences.getBool('gac_remember_me') == true) {
      await preferences.setString('gac_remember_email', profile.email);
    }
  }

  String _requireToken(SharedPreferences preferences) {
    final token = preferences.getString(gacAuthTokenKey);
    if (token == null || token.isEmpty) {
      throw const ProfileApiException(
        'Your session has expired. Sign in again.',
        status: 401,
      );
    }
    return token;
  }

  Uri _uri(String endpoint) => Uri.parse('${_baseUrl()}$endpoint');

  String _baseUrl() => apiUrl.replaceFirst(RegExp(r'/$'), '');

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map) return <String, dynamic>{};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  void _throwForResponse(
    http.Response response,
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final errors = _validationErrors(data['errors']);
    final firstError = errors.values
        .expand((messages) => messages)
        .cast<String?>()
        .firstOrNull;
    throw ProfileApiException(
      firstError ??
          (data['message'] is String ? data['message'] as String : fallback),
      status: response.statusCode,
      errors: errors,
    );
  }

  Map<String, List<String>> _validationErrors(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is List)
          entry.key as String: (entry.value as List)
              .whereType<String>()
              .toList(),
    };
  }
}

class ProfileApiException implements Exception {
  const ProfileApiException(
    this.message, {
    this.status = 0,
    this.errors = const {},
  });

  final String message;
  final int status;
  final Map<String, List<String>> errors;

  @override
  String toString() => message;
}
