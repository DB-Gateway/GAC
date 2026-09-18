import 'admin_data.dart';
import '../models/checklist_models.dart';

/// FY2025 Aftersales Standards Compliance Audit - Documentation Sheet
/// Checklist solely for CE Service users auditing service document utilization
/// across multiple customer repair orders (Customer 1, 2, 3...).
final List<ChecklistSection> dosDocumentationTemplate = [
  ChecklistSection(
    id: 'doc-rationalized-checksheet',
    title: 'Rationalized Checksheet',
    items: [
      ChecklistItem(
        id: 'doc-rc-1',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Uses latest Rationalized Checksheet (5k or 10k)',
        checker: 'CE SERVICE',
        bomTask: 'Verify rationalized checksheet revision used',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Verify current version 5k or 10k checksheet is attached.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-2',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Complete Name and Plate Number',
        checker: 'CE SERVICE',
        bomTask: 'Check vehicle and customer details completeness',
        escalation: 'AS BRAND HEAD',
        howToCheck:
            'Verify customer full name and vehicle plate number are written.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-3',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'PMS checklist is properly filled-out',
        checker: 'CE SERVICE',
        bomTask: 'Check completeness of PMS line items',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Verify all PMS checklist items are checked/accomplished.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-4',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Safety checklist is properly filled-out',
        checker: 'CE SERVICE',
        bomTask: 'Check safety inspection items completeness',
        escalation: 'AS BRAND HEAD',
        howToCheck:
            'Verify safety inspection checklist is filled out completely.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-5',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Carwash checklist is properly filled-out',
        checker: 'CE SERVICE',
        bomTask: 'Verify carwash inspection sheet',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Verify carwash completion check is recorded.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-6',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Final walk-around inspection checklist is properly filled-out',
        checker: 'CE SERVICE',
        bomTask: 'Check final walk-around checklist',
        escalation: 'AS BRAND HEAD',
        howToCheck:
            'Confirm final walk-around inspection section is completed.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-7',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: '10pts. Service Advisor Checklist is properly filled-out',
        checker: 'CE SERVICE',
        bomTask: 'Check 10-point SA checklist',
        escalation: 'AS BRAND HEAD',
        howToCheck:
            'Verify all 10 points in the SA checklist are accomplished.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-8',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "With SA' Signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify Service Advisor signature',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm SA signed the checksheet.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-9',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "With Technician's signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify Technician signature',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm attending technician signed the checksheet.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-10',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "With Leadman's signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify Leadman signature',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm Leadman/Foreman signature is present.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-rc-11',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "With customer's signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify customer signature on reception',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm customer signature acknowledging the checksheet.',
        response: 'YES',
      ),
    ],
  ),
  ChecklistSection(
    id: 'doc-repair-order',
    title: 'Repair Order',
    items: [
      ChecklistItem(
        id: 'doc-ro-1',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Complete customer and vehicle details',
        checker: 'CE SERVICE',
        bomTask: 'Check RO header details completeness',
        escalation: 'AS BRAND HEAD',
        howToCheck:
            'Confirm customer name, contact, VIN, plate number, mileage on RO.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-ro-2',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Promised time of delivery is indicated',
        checker: 'CE SERVICE',
        bomTask: 'Verify promised delivery time entry',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm promised delivery date and time are clearly written on RO.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-ro-3',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "With Customer's signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify customer authorization signature',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm customer signature authorizing the repair order.',
        response: 'YES',
      ),
    ],
  ),
  ChecklistSection(
    id: 'doc-service-invoice',
    title: 'Service Invoice',
    items: [
      ChecklistItem(
        id: 'doc-si-1',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Date/time actual repair time is indicated',
        checker: 'CE SERVICE',
        bomTask: 'Check actual repair time notation',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm actual date and time repair concluded is recorded on invoice.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-si-2',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: "Customer's and SA's signature",
        checker: 'CE SERVICE',
        bomTask: 'Verify release signatures',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm both customer and SA signed upon vehicle release.',
        response: 'YES',
      ),
      ChecklistItem(
        id: 'doc-si-3',
        level: 'Standard',
        coverage: 'Repair Order Completion and Invoicing',
        subject: 'Service Documents',
        text: 'Next PMS Schedule is indicated with MM360c App booking code',
        checker: 'CE SERVICE',
        bomTask: 'Check next PMS notation and MM360c booking code',
        escalation: 'AS BRAND HEAD',
        howToCheck: 'Confirm next PMS schedule and MM360c booking code are noted on invoice.',
        response: 'YES',
      ),
    ],
  ),
];

/// Data model representing a customer audit sample on the Documentation sheet.
class CustomerAuditSample {
  CustomerAuditSample({
    required this.customerIndex,
    this.roNumber = '',
    this.mileage = '',
    Map<String, String>? answers,
  }) : answers = answers ?? {};

  final int customerIndex;
  String roNumber;
  String mileage;
  final Map<String, String> answers;

  CustomerAuditSample copyWith({
    int? customerIndex,
    String? roNumber,
    String? mileage,
    Map<String, String>? answers,
  }) {
    return CustomerAuditSample(
      customerIndex: customerIndex ?? this.customerIndex,
      roNumber: roNumber ?? this.roNumber,
      mileage: mileage ?? this.mileage,
      answers: answers != null ? Map.of(answers) : Map.of(this.answers),
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_index': customerIndex,
    'ro_number': roNumber,
    'mileage': mileage,
    'answers': answers,
  };

  factory CustomerAuditSample.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['customer_index'];
    final rawAnswers = json['answers'];
    final answers = <String, String>{};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value != null) {
          answers[key] = value.toString();
        }
      }
    }

    return CustomerAuditSample(
      customerIndex: rawIndex is num
          ? rawIndex.toInt()
          : int.tryParse(rawIndex?.toString() ?? '') ?? 1,
      roNumber: json['ro_number']?.toString() ?? '',
      mileage: json['mileage']?.toString() ?? '',
      // Server encodes an empty PHP associative array as [] rather than {}.
      // Treat either empty shape as an empty answer map.
      answers: answers,
    );
  }
}

ChecklistTemplateData buildDocumentationTemplateData() {
  final sections = dosDocumentationTemplate
      .map((sec) {
        return ChecklistSectionData(
          id: 0,
          key: sec.id,
          title: sec.title,
          sortOrder: 0,
          metadata: const {'prerequisite_cascade': true},
          items: sec.items
              .map((item) {
                final itemNumber =
                    int.tryParse(item.id.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0;
                return ChecklistItemData(
                  id: itemNumber,
                  key: item.id,
                  prompt: item.text,
                  sortOrder: itemNumber,
                  metadata: {
                    'number': itemNumber,
                    'level': item.level,
                    'category': item.level,
                    'coverage': item.coverage,
                    'subject': item.subject,
                    'checker': item.checker,
                    'pic': 'CE SERVICE',
                    'bom_task': item.bomTask,
                    'escalation': item.escalation,
                    'how_to_check': item.howToCheck,
                    'prerequisite_cascade': true,
                  },
                );
              })
              .toList(growable: false),
        );
      })
      .toList(growable: false);

  return ChecklistTemplateData(
    id: 11,
    slug: 'dealer-operations-standards-documentation',
    name: 'Dealer Operations Standards - Documentation',
    description: 'FY2025 Aftersales Standards Compliance Audit Documentation Sheet (17 Standards). Exclusively for CE Service users. Multi-customer audit where every question is a prerequisite: choosing No on any question automatically cascades all check items for that customer to No.',
    version: 1,
    settings: const {
      'validation_mode': 'dos_documentation',
      'response_options': ['yes', 'no', 'na'],
      'instructions': 'Audit service documents (Rationalized Checksheet, Repair Order, Service Invoice) across multiple customers. Note: Every question is a prerequisite. Choosing "No" on any question automatically sets all 17 check items for that customer to No, exempting Type of Job (mileage) and R.O. number.',
      'prerequisite_cascade': true,
      'multi_customer': true,
      'default_customer_count': 3,
    },
    sections: sections,
  );
}
