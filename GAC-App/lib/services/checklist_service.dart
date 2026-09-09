import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/checklist_models.dart';

abstract interface class ChecklistRepository {
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date});

  Future<ChecklistLoadResult> fetchChecklist(String slug, {String? date});

  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  });

  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  });

  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  });
}

class ChecklistApiService implements ChecklistRepository {
  ChecklistApiService({
    http.Client? client,
    this.apiUrl = gacApiUrl,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _client = client ?? http.Client(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final http.Client _client;
  final String apiUrl;
  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<List<ChecklistCatalogItem>> fetchCatalog({String? date}) async {
    final data = await _request(
      'GET',
      '/checklists',
      query: date == null ? null : {'date': date},
    );
    final checklists = data['checklists'];
    if (checklists is! List) {
      throw const ChecklistApiException(
        'Laravel returned an invalid checklist list.',
      );
    }
    try {
      return checklists
          .map(ChecklistCatalogItem.fromJson)
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ChecklistApiException(error.message);
    }
  }

  @override
  Future<ChecklistLoadResult> fetchChecklist(
    String slug, {
    String? date,
  }) async {
    final data = await _request(
      'GET',
      '/checklists/${Uri.encodeComponent(slug)}',
      query: date == null ? null : {'date': date},
    );
    try {
      return ChecklistLoadResult.fromJson(data);
    } on FormatException catch (error) {
      throw ChecklistApiException(error.message);
    }
  }

  @override
  Future<ChecklistSubmissionData> saveDraft(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) => _save(slug, action: 'draft', date: date, responses: responses);

  @override
  Future<ChecklistSubmissionData> submit(
    String slug, {
    required String date,
    required List<Map<String, dynamic>> responses,
  }) => _save(slug, action: 'submit', date: date, responses: responses);

  @override
  Future<Map<String, dynamic>> uploadAttachment(
    String slug, {
    required List<int> bytes,
    required String filename,
  }) async {
    final preferences = await _preferencesLoader();
    final token = preferences.getString(gacAuthTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const ChecklistApiException(
        'Your session has expired. Sign in again.',
        status: 401,
      );
    }

    final base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse(
      '$base/checklists/${Uri.encodeComponent(slug)}/attachments',
    );

    late final http.Response response;
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..files.add(
          http.MultipartFile.fromBytes('photo', bytes, filename: filename),
        );
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
    } catch (_) {
      throw ChecklistApiException(
        'Cannot reach Laravel at $base. Check your network connection.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map
        ? {
            for (final entry in decoded.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _firstValidationMessage(data['errors']) ??
          checklistJsonNullableString(data['message']) ??
          'Photo upload failed.';
      throw ChecklistApiException(message, status: response.statusCode);
    }

    return data;
  }

  Future<ChecklistSubmissionData> _save(
    String slug, {
    required String action,
    required String date,
    required List<Map<String, dynamic>> responses,
  }) async {
    final data = await _request(
      'POST',
      '/checklists/${Uri.encodeComponent(slug)}/$action',
      body: {'date': date, 'responses': responses},
    );
    try {
      return ChecklistSubmissionData.fromJson(data['submission']);
    } on FormatException catch (error) {
      throw ChecklistApiException(error.message);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final preferences = await _preferencesLoader();
    final token = preferences.getString(gacAuthTokenKey);
    if (token == null || token.isEmpty) {
      throw const ChecklistApiException(
        'Your session has expired. Sign in again.',
        status: 401,
      );
    }

    final base = apiUrl.replaceFirst(RegExp(r'/$'), '');
    final filteredQuery = <String, String>{};
    if (query != null) {
      for (final entry in query.entries) {
        if (entry.value.isNotEmpty) filteredQuery[entry.key] = entry.value;
      }
    }
    final uri = Uri.parse('$base$endpoint')
        .replace(queryParameters: filteredQuery.isEmpty ? null : filteredQuery);

    late final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        });
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
    } catch (_) {
      throw ChecklistApiException(
        'Cannot reach Laravel at $base. Check that the API server and network are available.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final data = decoded is Map
        ? {
            for (final entry in decoded.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          _firstValidationMessage(data['errors']) ??
          checklistJsonNullableString(data['message']) ??
          'The checklist request failed.';
      throw ChecklistApiException(message, status: response.statusCode);
    }
    if (data.isEmpty) {
      throw ChecklistApiException(
        'Laravel returned an empty response.',
        status: response.statusCode,
      );
    }
    return data;
  }

  String? _firstValidationMessage(Object? value) {
    if (value is! Map) return null;
    for (final messages in value.values) {
      if (messages is List) {
        for (final message in messages) {
          if (message is String) return message;
        }
      }
    }
    return null;
  }
}

class ChecklistApiException implements Exception {
  const ChecklistApiException(this.message, {this.status = 0});

  final String message;
  final int status;

  @override
  String toString() => message;
}
