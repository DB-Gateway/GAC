import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart' show normalizeUserType;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.branch,
    required this.userType,
    required this.accountStatus,
  });

  final int id;
  final String name;
  final String email;
  final String? branch;
  final String userType;
  final String accountStatus;

  factory AuthUser.fromJson(Object? value) {
    final data = _stringKeyedMap(value);
    if (data == null ||
        data['id'] is! int ||
        data['name'] is! String ||
        data['email'] is! String ||
        (data['branch'] != null && data['branch'] is! String) ||
        data['user_type'] is! String ||
        data['account_status'] is! String) {
      throw const UserManagementApiException(
        'Server returned an invalid user response.',
        status: 0,
      );
    }

    final accountStatus = data['account_status'] as String;
    if (accountStatus != 'pending' &&
        accountStatus != 'active' &&
        accountStatus != 'rejected') {
      throw const UserManagementApiException(
        'Server returned an invalid user response.',
        status: 0,
      );
    }

    return AuthUser(
      id: data['id'] as int,
      name: data['name'] as String,
      email: data['email'] as String,
      branch: data['branch'] as String?,
      userType: normalizeUserType(data['user_type'] as String),
      accountStatus: accountStatus,
    );
  }
}

class PendingUser extends AuthUser {
  const PendingUser({
    required super.id,
    required super.name,
    required super.email,
    required super.branch,
    required super.userType,
    required super.accountStatus,
    required this.createdAt,
  });

  final String createdAt;

  factory PendingUser.fromJson(Object? value) {
    final data = _stringKeyedMap(value);
    if (data == null || data['created_at'] is! String) {
      throw const UserManagementApiException(
        'Server returned an invalid pending-user response.',
        status: 0,
      );
    }
    final user = AuthUser.fromJson(data);
    return PendingUser(
      id: user.id,
      name: user.name,
      email: user.email,
      branch: user.branch,
      userType: user.userType,
      accountStatus: user.accountStatus,
      createdAt: data['created_at'] as String,
    );
  }
}

class UserManagementApiException implements Exception {
  const UserManagementApiException(
    this.message, {
    required this.status,
    this.errors = const {},
  });

  final String message;
  final int status;
  final Map<String, List<String>> errors;

  @override
  String toString() => message;
}

Future<List<PendingUser>> getPendingUsers() async {
  final result = await _authenticatedRequest('/users/pending');
  final users = result['users'];
  if (users is! List) {
    throw const UserManagementApiException(
      'Server returned an invalid pending-users response.',
      status: 0,
    );
  }
  return users.map(PendingUser.fromJson).toList(growable: false);
}

Future<AuthUser> approveUser(int userId) =>
    _updateUserApproval(userId, action: 'approve');

Future<AuthUser> rejectUser(int userId) =>
    _updateUserApproval(userId, action: 'reject');

Future<AuthUser> _updateUserApproval(
  int userId, {
  required String action,
}) async {
  final result = await _authenticatedRequest(
    '/users/$userId/$action',
    method: 'PATCH',
  );
  return AuthUser.fromJson(result['user']);
}

Future<Map<String, dynamic>> _authenticatedRequest(
  String endpoint, {
  String method = 'GET',
}) async {
  final preferences = await SharedPreferences.getInstance();
  final token = preferences.getString(gacAuthTokenKey);
  if (token == null || token.isEmpty) {
    throw const UserManagementApiException(
      'You are not logged in.',
      status: 401,
    );
  }

  final apiUrl = gacApiUrl.replaceFirst(RegExp(r'/$'), '');
  late final http.Response response;
  try {
    final request = http.Request(method, Uri.parse('$apiUrl$endpoint'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
    response = await http.Response.fromStream(await request.send());
  } catch (_) {
    throw UserManagementApiException(
      'Cannot reach Server at $apiUrl. Make sure the API server is running.',
      status: 0,
    );
  }

  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = null;
  }
  final data = _stringKeyedMap(decoded);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    final errors = _validationErrors(data?['errors']);
    final firstValidationError = errors.values
        .expand((messages) => messages)
        .firstOrNull;
    final responseMessage = data?['message'];
    throw UserManagementApiException(
      firstValidationError ??
          (responseMessage is String ? responseMessage : null) ??
          'The request failed.',
      status: response.statusCode,
      errors: errors,
    );
  }

  if (data == null) {
    throw UserManagementApiException(
      'Server returned an empty response.',
      status: response.statusCode,
    );
  }
  return data;
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

Map<String, List<String>> _validationErrors(Object? value) {
  final data = _stringKeyedMap(value);
  if (data == null) return const {};
  return {
    for (final entry in data.entries)
      if (entry.value is List)
        entry.key: (entry.value as List).whereType<String>().toList(),
  };
}
