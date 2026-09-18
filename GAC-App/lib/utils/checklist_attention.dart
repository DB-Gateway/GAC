import '../data/dos_sales_data.dart';
import '../models/authenticated_user.dart';
import '../models/checklist_models.dart';

class ChecklistAttentionTarget {
  const ChecklistAttentionTarget({
    required this.itemKey,
    this.slotKey,
    this.customerIndex,
  });

  final String itemKey;
  final String? slotKey;
  final int? customerIndex;
}

/// Uses the same answer fields and item scope as the checklist detail screen.
/// Notes, historical flags, and aggregate scores cannot make a YES an issue.
List<ChecklistAttentionTarget> checklistAttentionTargets(
  ChecklistLoadResult record,
  AuthenticatedUser user,
) {
  final template = record.template.slug == 'dealer-operations-standards-sales'
      ? buildDosSalesTemplateData(source: record.template)
      : record.template;
  final responses = record.submission?.responses;
  if (responses == null || responses.isEmpty) return const [];
  final hourly =
      template.validationMode == 'time_slots' ||
      template.slug == 'restroom' ||
      template.slug == 'utilities';
  final documentation =
      template.validationMode == 'dos_documentation' ||
      template.slug == 'dealer-operations-standards-documentation';
  final roleScoped =
      template.validationMode == 'dos' ||
      template.validationMode == 'dos_subform';
  final targets = <ChecklistAttentionTarget>[];
  final customers = responses.values.first.details['customers'];

  for (final item in template.sections.expand((section) => section.items)) {
    if (roleScoped && !user.isAdmin && !user.matchesCheckerRole(item.checker)) {
      continue;
    }
    if (documentation) {
      if (customers is! List) continue;
      for (final customer in customers) {
        if (customer is! Map || customer['answers'] is! Map) continue;
        final index = int.tryParse('${customer['customer_index']}');
        if (index == null) continue;
        if (checklistResponseNeedsAttention(customer['answers'][item.key])) {
          targets.add(
            ChecklistAttentionTarget(itemKey: item.key, customerIndex: index),
          );
        }
      }
      continue;
    }
    final response = responses[item.key];
    if (response == null) continue;
    if (hourly) {
      final slots = response.details['slots'];
      if (slots is! Map) continue;
      for (final slot in template.timeSlots) {
        if (item.isSlotActive(slot.key) &&
            checklistResponseNeedsAttention(slots[slot.key])) {
          targets.add(
            ChecklistAttentionTarget(itemKey: item.key, slotKey: slot.key),
          );
        }
      }
    } else if (checklistResponseNeedsAttention(response.status)) {
      targets.add(ChecklistAttentionTarget(itemKey: item.key));
    }
  }
  return targets;
}

bool checklistResponseNeedsAttention(Object? value) => const {
  'no',
  'na',
  'not_good',
  'bad',
  'non_compliant',
  'fail',
  'rejected',
}.contains(value?.toString().trim().toLowerCase());
