import '../models/checklist_models.dart';

/// Returns the scheduled slot that corresponds to the device's local time.
///
/// When the current time falls between scheduled slots, the next slot is used.
/// Before/after the schedule, this mirrors the checklist detail screen by
/// choosing the first/last slot respectively.
String? checklistSlotForLocalTime(
  ChecklistCatalogItem checklist,
  DateTime localTime,
) {
  final usesTimeSlots =
      checklist.settings['validation_mode'] == 'time_slots' ||
      checklist.slug == 'restroom' ||
      checklist.slug.startsWith('restroom') ||
      checklist.slug == 'utilities';
  if (!usesTimeSlots) return null;

  final rawSlots = checklist.settings['time_slots'];
  if (rawSlots is! List || rawSlots.isEmpty) return null;

  final slots = <({String key, int minuteOfDay})>[];
  for (final rawSlot in rawSlots) {
    final String? key;
    if (rawSlot is String) {
      key = rawSlot;
    } else if (rawSlot is Map) {
      key = rawSlot['key']?.toString();
    } else {
      key = null;
    }

    if (key == null) continue;
    final parts = key.split(':');
    if (parts.isEmpty || parts.length > 2) continue;
    final hour = int.tryParse(parts[0]);
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : 0;
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      continue;
    }
    slots.add((key: key, minuteOfDay: hour * 60 + minute));
  }

  if (slots.isEmpty) return null;
  slots.sort((left, right) => left.minuteOfDay.compareTo(right.minuteOfDay));

  final currentMinute = localTime.hour * 60 + localTime.minute;
  for (final slot in slots) {
    if (currentMinute >= slot.minuteOfDay &&
        currentMinute < slot.minuteOfDay + 60) {
      return slot.key;
    }
  }
  for (final slot in slots) {
    if (currentMinute < slot.minuteOfDay) return slot.key;
  }
  return slots.last.key;
}
