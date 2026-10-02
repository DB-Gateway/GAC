import 'package:flutter/foundation.dart';

import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';
import 'checklist_service.dart';

/// Result of a 5S Utilities missed checklist inspection check and synchronization.
class UtilitiesChecklistSyncResult {
  const UtilitiesChecklistSyncResult({
    required this.autoSubmitted,
    required this.missedSlots,
    this.activeDueSlot,
    this.submission,
    this.missedSlotsByChecklist = const {},
  });

  final bool autoSubmitted;
  final List<String> missedSlots;
  final String? activeDueSlot;
  final ChecklistSubmissionData? submission;
  final Map<String, List<String>> missedSlotsByChecklist;

  String get formattedMissedSlots {
    if (missedSlots.isEmpty) return '';
    return missedSlots.map(formatSlotKey).join(', ');
  }

  static String formatSlotKey(String key) {
    final parts = key.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
    if (hour == null || minute == null) return key;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $suffix';
  }
}

/// Service to handle scheduled 5S Utilities inspection missed-submission recording
/// and due submission prompts.
class UtilitiesMissedChecklistService {
  const UtilitiesMissedChecklistService._();

  static const List<String> defaultUtilitiesSlots = [
    '08:00',
    '11:00',
    '14:00',
    '16:00',
  ];

  static bool isUtilitiesUser(AuthenticatedUser? user) {
    if (user == null) return false;
    return user.is5sUtilities || user.isUtilities;
  }

  /// Checks every assigned Utilities/restroom checklist for missed slots.
  /// If current time has passed an inspection slot window without submission,
  /// automatically marks the active items for that slot as 'not_good' ("NO")
  /// and submits the checklist to the server.
  /// Also detects if an inspection slot (e.g. 8:00 AM) is currently active and due.
  static Future<UtilitiesChecklistSyncResult?> syncMissedUtilitiesChecklist({
    required ChecklistRepository repository,
    required AuthenticatedUser user,
    DateTime? now,
    String? date,
    List<ChecklistCatalogItem>? catalog,
  }) async {
    if (!isUtilitiesUser(user)) return null;

    final currentTime = now ?? DateTime.now();
    final dateStr = date ?? _formatDate(currentTime);

    if (catalog == null) {
      try {
        catalog = await repository.fetchCatalog(date: dateStr);
      } catch (e) {
        debugPrint(
          'UtilitiesMissedChecklistService: could not load catalog: $e',
        );
        return null;
      }
    }

    final checklists = catalog.where(
      (item) => item.slug == 'utilities' || item.slug.startsWith('restroom'),
    );
    final missedByChecklist = <String, List<String>>{};
    String? activeDueSlot;
    ChecklistSubmissionData? latestSubmission;
    var autoSubmitted = false;
    for (final checklist in checklists) {
      final result = await _syncChecklist(
        repository: repository,
        slug: checklist.slug,
        currentTime: currentTime,
        dateStr: dateStr,
      );
      if (result == null) continue;
      if (result.missedSlots.isNotEmpty) {
        missedByChecklist[checklist.slug] = result.missedSlots;
      }
      autoSubmitted |= result.autoSubmitted;
      activeDueSlot ??= result.activeDueSlot;
      latestSubmission = result.submission ?? latestSubmission;
    }
    return UtilitiesChecklistSyncResult(
      autoSubmitted: autoSubmitted,
      missedSlots: missedByChecklist.values
          .expand((slots) => slots)
          .toSet()
          .toList(),
      missedSlotsByChecklist: missedByChecklist,
      activeDueSlot: activeDueSlot,
      submission: latestSubmission,
    );
  }

  static Future<UtilitiesChecklistSyncResult?> _syncChecklist({
    required ChecklistRepository repository,
    required String slug,
    required DateTime currentTime,
    required String dateStr,
  }) async {
    ChecklistLoadResult record;
    try {
      record = await repository.fetchChecklist(slug, date: dateStr);
    } catch (e) {
      debugPrint('UtilitiesMissedChecklistService: could not load $slug: $e');
      return null;
    }

    final template = record.template;
    final submission = record.submission;

    final rawSlots = template.timeSlots.isNotEmpty
        ? template.timeSlots
        : defaultUtilitiesSlots
              .map((k) => ChecklistTimeSlot(key: k, label: k))
              .toList(growable: false);

    final auditDateTime =
        _parseDate(dateStr) ??
        DateTime(currentTime.year, currentTime.month, currentTime.day);

    final missedSlots = <ChecklistTimeSlot>[];
    String? activeDueSlotKey;

    for (final slot in rawSlots) {
      final slotStart = _slotStart(slot.key, auditDateTime);
      if (slotStart == null) continue;
      if (!template.sections
          .expand((section) => section.items)
          .any((item) => item.isSlotActive(slot.key))) {
        continue;
      }
      final slotEnd = slotStart.add(const Duration(hours: 1));

      final isExpired = !currentTime.isBefore(slotEnd);
      final isActive =
          !currentTime.isBefore(slotStart) && currentTime.isBefore(slotEnd);

      final isSubmitted = _isSlotSubmitted(slot.key, template, submission);

      if (!isSubmitted) {
        if (isExpired) {
          missedSlots.add(slot);
        } else if (isActive && activeDueSlotKey == null) {
          activeDueSlotKey = slot.key;
        }
      }
    }

    if (missedSlots.isEmpty) {
      return UtilitiesChecklistSyncResult(
        autoSubmitted: false,
        missedSlots: const [],
        activeDueSlot: activeDueSlotKey,
        submission: submission,
      );
    }

    // Prepare responses payload with missed slots marked as 'not_good' ("NO")
    final responsesPayload = <Map<String, dynamic>>[];
    final items = template.sections.expand((section) => section.items).toList();

    for (final item in items) {
      final existingResponse = submission?.responses[item.key];
      final rawSlots = existingResponse?.details['slots'];
      final rawSubmittedSlots = existingResponse?.details['submitted_slots'];

      final slotsMap = <String, String>{
        if (rawSlots is Map)
          for (final entry in rawSlots.entries)
            if (entry.key is String && entry.value is String)
              entry.key as String: entry.value as String,
      };

      final submittedSet = <String>{
        if (rawSubmittedSlots is Iterable)
          for (final slotKey in rawSubmittedSlots)
            if (slotKey is String && slotKey.trim().isNotEmpty) slotKey.trim(),
      };
      var markedMissed = false;

      for (final missedSlot in missedSlots) {
        if (item.isSlotActive(missedSlot.key)) {
          if (!submittedSet.contains(missedSlot.key)) {
            slotsMap[missedSlot.key] = 'not_good';
            markedMissed = true;
          }
          submittedSet.add(missedSlot.key);
        }
      }

      final details = <String, dynamic>{
        ...?existingResponse?.details,
        if (slotsMap.isNotEmpty) 'slots': slotsMap,
        if (submittedSet.isNotEmpty)
          'submitted_slots': (submittedSet.toList()..sort()),
        'client_time': currentTime.toIso8601String(),
      };

      responsesPayload.add({
        'item_id': item.id,
        'item_key': item.key,
        'status': null,
        'remark': existingResponse?.remark?.trim().isNotEmpty == true
            ? existingResponse!.remark
            : (markedMissed
                  ? 'Failed to conduct the checklist on time.'
                  : existingResponse?.remark),
        'finding': existingResponse?.finding,
        'action_plan': null,
        'commitment_date': null,
        'attachment_path': existingResponse?.attachmentPath,
        'details': details,
      });
    }

    try {
      final updatedSubmission = await repository.submit(
        template.slug,
        date: dateStr,
        responses: responsesPayload,
      );

      return UtilitiesChecklistSyncResult(
        autoSubmitted: true,
        missedSlots: missedSlots.map((s) => s.key).toList(),
        activeDueSlot: activeDueSlotKey,
        submission: updatedSubmission,
      );
    } catch (e) {
      debugPrint('UtilitiesMissedChecklistService: submission failed: $e');
      return UtilitiesChecklistSyncResult(
        autoSubmitted: false,
        missedSlots: missedSlots.map((s) => s.key).toList(),
        activeDueSlot: activeDueSlotKey,
        submission: submission,
      );
    }
  }

  static bool _isSlotSubmitted(
    String slotKey,
    ChecklistTemplateData template,
    ChecklistSubmissionData? submission,
  ) {
    if (submission == null) return false;
    final responses = submission.responses;
    if (responses.isEmpty) return false;

    // A saved draft is not a submitted inspection. Every active item must
    // carry the slot's submission marker, unless this is a legacy submitted
    // record that only stores the answers.
    final items = template.sections
        .expand((s) => s.items)
        .where((i) => i.isSlotActive(slotKey))
        .toList();
    if (items.isEmpty) return false;

    for (final item in items) {
      final resp = responses[item.key];
      final rawSubmitted = resp?.details['submitted_slots'];
      if (rawSubmitted is Iterable && rawSubmitted.contains(slotKey)) {
        continue;
      }
      if (!submission.isSubmitted) return false;
      final mark = resp?.details['slots']?[slotKey]
          ?.toString()
          .trim()
          .toLowerCase();
      if (mark == null || mark.isEmpty || mark == 'unanswered') {
        return false;
      }
    }

    return true;
  }

  static DateTime? _slotStart(String slotKey, DateTime auditDate) {
    final parts = slotKey.split(':');
    if (parts.isEmpty || parts.length > 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : 0;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(
      auditDate.year,
      auditDate.month,
      auditDate.day,
      hour,
      minute,
    );
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
