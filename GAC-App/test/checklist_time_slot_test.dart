import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/utils/checklist_time_slot.dart';

void main() {
  const checklist = ChecklistCatalogItem(
    id: 1,
    slug: 'utilities',
    name: 'Utilities',
    description: null,
    version: 1,
    settings: {
      'validation_mode': 'time_slots',
      'time_slots': [
        {'key': '08:00'},
        {'key': '09:00'},
        {'key': '11:00'},
        {'key': '13:00'},
        {'key': '14:00'},
        {'key': '17:00'},
      ],
    },
    sectionCount: 1,
    itemCount: 1,
    submission: null,
  );

  test('selects the hourly slot matching the device local time', () {
    expect(
      checklistSlotForLocalTime(checklist, DateTime(2026, 9, 10, 14, 37)),
      '14:00',
    );
  });

  test('uses the next scheduled slot during a schedule gap', () {
    expect(
      checklistSlotForLocalTime(checklist, DateTime(2026, 9, 10, 12, 30)),
      '13:00',
    );
  });

  test('clamps device time to the first and last scheduled slots', () {
    expect(
      checklistSlotForLocalTime(checklist, DateTime(2026, 9, 10, 6, 30)),
      '08:00',
    );
    expect(
      checklistSlotForLocalTime(checklist, DateTime(2026, 9, 10, 20, 30)),
      '17:00',
    );
  });
}
