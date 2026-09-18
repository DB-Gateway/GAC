class ChecklistCatalogItem {
  const ChecklistCatalogItem({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.version,
    required this.settings,
    required this.sectionCount,
    required this.itemCount,
    required this.submission,
    this.workUnitCount,
  });

  final int id;
  final String slug;
  final String name;
  final String? description;
  final int version;
  final Map<String, dynamic> settings;
  final int sectionCount;
  final int itemCount;
  final int? workUnitCount;
  final ChecklistSubmissionData? submission;

  int get totalWorkUnits {
    final explicitTotal = workUnitCount;
    if (explicitTotal != null && explicitTotal >= 0) return explicitTotal;

    if (settings['validation_mode'] == 'time_slots') {
      final slots = settings['time_slots'];
      if (slots is List && slots.isNotEmpty) return itemCount * slots.length;
    }

    return itemCount;
  }

  String get categoryLabel => switch (slug) {
    'gateway-5s' => '5S',
    'sales' => 'SALES',
    'service' => 'SERVICE',
    'dealer-operations-standards' ||
    'dealer-operations-standards-sales' => 'DOS',
    'restroom' || 'utilities' => 'UTILITIES',
    _ => 'CHECKLIST',
  };

  factory ChecklistCatalogItem.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'checklist');
    return ChecklistCatalogItem(
      id: checklistJsonInt(data['id'], label: 'checklist.id'),
      slug: checklistJsonString(data['slug'], label: 'checklist.slug'),
      name: checklistJsonString(data['name'], label: 'checklist.name'),
      description: checklistJsonNullableString(data['description']),
      version: checklistJsonInt(data['version'], label: 'checklist.version'),
      settings: checklistJsonOptionalMap(data['settings']),
      sectionCount: checklistJsonInt(
        data['section_count'],
        label: 'checklist.section_count',
      ),
      itemCount: checklistJsonInt(
        data['item_count'],
        label: 'checklist.item_count',
      ),
      workUnitCount: checklistJsonNullableInt(data['work_unit_count']),
      submission: data['submission'] == null
          ? null
          : ChecklistSubmissionData.fromJson(data['submission']),
    );
  }

  ChecklistCatalogItem copyWith({
    int? id,
    String? slug,
    String? name,
    String? description,
    int? version,
    Map<String, dynamic>? settings,
    int? sectionCount,
    int? itemCount,
    int? workUnitCount,
    ChecklistSubmissionData? submission,
    bool clearSubmission = false,
  }) {
    return ChecklistCatalogItem(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      settings: settings ?? this.settings,
      sectionCount: sectionCount ?? this.sectionCount,
      itemCount: itemCount ?? this.itemCount,
      workUnitCount: workUnitCount ?? this.workUnitCount,
      submission: clearSubmission ? null : (submission ?? this.submission),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'description': description,
    'version': version,
    'settings': settings,
    'section_count': sectionCount,
    'item_count': itemCount,
    if (workUnitCount != null) 'work_unit_count': workUnitCount,
  };
}

class ChecklistTemplateData {
  const ChecklistTemplateData({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.version,
    required this.settings,
    required this.sections,
  });

  final int id;
  final String slug;
  final String name;
  final String? description;
  final int version;
  final Map<String, dynamic> settings;
  final List<ChecklistSectionData> sections;

  String get validationMode =>
      checklistJsonNullableString(settings['validation_mode']) ?? 'yes_no_na';

  String? get instructions =>
      checklistJsonNullableString(settings['instructions']);

  List<ChecklistTimeSlot> get timeSlots {
    final raw = settings['time_slots'];
    if (raw is! List) return const [];
    return raw.map(ChecklistTimeSlot.fromJson).toList(growable: false);
  }

  int get itemCount =>
      sections.fold(0, (total, section) => total + section.items.length);

  factory ChecklistTemplateData.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'template');
    final sections = data['sections'];
    if (sections is! List) {
      throw const FormatException(
        'Server returned invalid template sections.',
      );
    }
    return ChecklistTemplateData(
      id: checklistJsonInt(data['id'], label: 'template.id'),
      slug: checklistJsonString(data['slug'], label: 'template.slug'),
      name: checklistJsonString(data['name'], label: 'template.name'),
      description: checklistJsonNullableString(data['description']),
      version: checklistJsonInt(data['version'], label: 'template.version'),
      settings: checklistJsonOptionalMap(data['settings']),
      sections: sections
          .map(ChecklistSectionData.fromJson)
          .toList(growable: false),
    );
  }
}

class ChecklistSectionData {
  const ChecklistSectionData({
    required this.id,
    required this.key,
    required this.title,
    required this.sortOrder,
    required this.metadata,
    required this.items,
  });

  final int id;
  final String key;
  final String title;
  final int sortOrder;
  final Map<String, dynamic> metadata;
  final List<ChecklistItemData> items;

  factory ChecklistSectionData.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'section');
    final items = data['items'];
    if (items is! List) {
      throw const FormatException('Server returned invalid checklist items.');
    }
    return ChecklistSectionData(
      id: checklistJsonInt(data['id'], label: 'section.id'),
      key: checklistJsonString(data['key'], label: 'section.key'),
      title: checklistJsonString(data['title'], label: 'section.title'),
      sortOrder: checklistJsonInt(
        data['sort_order'],
        label: 'section.sort_order',
      ),
      metadata: checklistJsonOptionalMap(data['metadata']),
      items: items.map(ChecklistItemData.fromJson).toList(growable: false),
    );
  }
}

class ChecklistItemData {
  const ChecklistItemData({
    required this.id,
    required this.key,
    required this.prompt,
    required this.sortOrder,
    required this.metadata,
    this.description,
    this.isActive = true,
    this.activeSlots,
  });

  final int id;
  final String key;
  final String prompt;
  final int sortOrder;
  final Map<String, dynamic> metadata;
  final String? description;
  final bool isActive;
  final List<String>? activeSlots;

  String? get subject => checklistJsonNullableString(metadata['subject']);
  String? get level =>
      checklistJsonNullableString(metadata['level']) ??
      checklistJsonNullableString(metadata['category']);
  String? get category => level;
  String? get coverage => checklistJsonNullableString(metadata['coverage']);
  String? get pic => checklistJsonNullableString(metadata['pic']);
  String? get checker => checklistJsonNullableString(metadata['checker']);
  String? get escalation => checklistJsonNullableString(metadata['escalation']);
  String? get bomTask =>
      checklistJsonNullableString(metadata['bom_task']) ??
      checklistJsonNullableString(metadata['bomTask']);
  String? get howToCheck =>
      checklistJsonNullableString(metadata['how_to_check']) ??
      checklistJsonNullableString(metadata['howToCheck']);
  String? get displayNumber => metadata['number']?.toString();

  bool isSlotActive(String slotKey) {
    if (!isActive) return false;
    if (activeSlots != null) {
      return activeSlots!.contains(slotKey);
    }
    final metaSlots = metadata['active_slots'];
    if (metaSlots is List) {
      return metaSlots.map((e) => e.toString().trim()).contains(slotKey);
    }
    return true;
  }

  factory ChecklistItemData.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'item');
    final metadata = Map<String, dynamic>.from(
      checklistJsonOptionalMap(data['metadata']),
    );
    if (data['how_to_check'] != null && !metadata.containsKey('how_to_check')) {
      metadata['how_to_check'] = data['how_to_check'];
    }
    if (data['howToCheck'] != null && !metadata.containsKey('howToCheck')) {
      metadata['howToCheck'] = data['howToCheck'];
    }

    final rawIsActive = data['is_active'] ?? metadata['is_active'];
    final isActive = rawIsActive is bool
        ? rawIsActive
        : rawIsActive == null
            ? true
            : (rawIsActive.toString() == '1' ||
                rawIsActive.toString().toLowerCase() == 'true');

    final rawActiveSlots = data['active_slots'] ?? metadata['active_slots'];
    List<String>? activeSlots;
    if (rawActiveSlots is List) {
      activeSlots = rawActiveSlots
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    return ChecklistItemData(
      id: checklistJsonInt(data['id'], label: 'item.id'),
      key: checklistJsonString(data['key'], label: 'item.key'),
      prompt: checklistJsonString(data['prompt'], label: 'item.prompt'),
      sortOrder: checklistJsonInt(data['sort_order'], label: 'item.sort_order'),
      metadata: metadata,
      description:
          checklistJsonNullableString(data['description']) ??
          (data['metadata'] is Map
              ? checklistJsonNullableString(
                  (data['metadata'] as Map)['description'],
                )
              : null),
      isActive: isActive,
      activeSlots: activeSlots,
    );
  }
}

class ChecklistTimeSlot {
  const ChecklistTimeSlot({required this.key, required this.label});

  final String key;
  final String label;

  factory ChecklistTimeSlot.fromJson(Object? value) {
    if (value is String) return ChecklistTimeSlot(key: value, label: value);
    final data = checklistJsonMap(value, label: 'time slot');
    final key = checklistJsonString(data['key'], label: 'time_slot.key');
    return ChecklistTimeSlot(
      key: key,
      label: checklistJsonNullableString(data['label']) ?? key,
    );
  }
}

class ChecklistSubmissionData {
  const ChecklistSubmissionData({
    required this.id,
    required this.status,
    required this.auditDate,
    required this.templateVersion,
    required this.scores,
    required this.responses,
    required this.answeredItems,
    required this.totalItems,
    required this.completionPercentage,
    required this.submittedAt,
    this.issueCount,
  });

  final int id;
  final String status;
  final String? auditDate;
  final int templateVersion;
  final Map<String, dynamic> scores;
  final Map<String, ChecklistResponseData> responses;
  final int? answeredItems;
  final int? totalItems;
  final double? completionPercentage;
  final DateTime? submittedAt;
  final int? issueCount;

  bool get isSubmitted {
    final s = status.trim().toLowerCase();
    return s == 'submitted' || s == 'completed';
  }

  int get effectiveAnsweredItems {
    if (answeredItems != null && answeredItems! > 0) {
      return answeredItems!;
    }
    if (responses.isNotEmpty) {
      return responses.values.where((r) {
        final st = r.status?.trim().toLowerCase();
        if (st != null && st.isNotEmpty && st != 'unanswered') return true;
        final choice = r.details['choice']?.toString().trim().toLowerCase();
        if (choice != null && choice.isNotEmpty && choice != 'unanswered') {
          return true;
        }
        final slots = r.details['slots'];
        if (slots is Map) {
          return slots.values.any((s) {
            final mark = s?.toString().trim().toLowerCase();
            return mark != null && mark.isNotEmpty && mark != 'unanswered';
          });
        }
        return false;
      }).length;
    }
    return answeredItems ?? 0;
  }

  bool get hasStarted =>
      effectiveAnsweredItems > 0 || (completionPercentage ?? 0.0) > 0.0;

  int get issues =>
      issueCount ??
      checklistJsonNullableInt(scores['bad']) ??
      checklistJsonNullableInt(scores['no']) ??
      0;

  factory ChecklistSubmissionData.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'submission');
    final rawResponses = checklistJsonOptionalMap(data['responses']);
    return ChecklistSubmissionData(
      id: checklistJsonInt(data['id'], label: 'submission.id'),
      status: checklistJsonString(data['status'], label: 'submission.status'),
      auditDate: checklistJsonNullableString(data['audit_date']),
      templateVersion: checklistJsonInt(
        data['template_version'],
        label: 'submission.template_version',
      ),
      scores: checklistJsonOptionalMap(data['scores']),
      responses: {
        for (final entry in rawResponses.entries)
          entry.key: ChecklistResponseData.fromJson(entry.value),
      },
      answeredItems: checklistJsonNullableInt(data['answered_items']),
      totalItems: checklistJsonNullableInt(data['total_items']),
      completionPercentage: checklistJsonNullableDouble(
        data['completion_percentage'],
      ),
      submittedAt: DateTime.tryParse(
        checklistJsonNullableString(data['submitted_at']) ?? '',
      ),
      issueCount: checklistJsonNullableInt(data['issue_count']),
    );
  }
}

class ChecklistResponseData {
  const ChecklistResponseData({
    required this.itemId,
    required this.itemKey,
    required this.status,
    required this.remark,
    required this.finding,
    required this.actionPlan,
    required this.commitmentDate,
    required this.details,
    this.legacyEscalation,
    this.attachmentPath,
    this.attachmentUrl,
  });

  final int? itemId;
  final String? itemKey;
  final String? status;
  final String? remark;
  final String? finding;
  final String? actionPlan;
  final String? commitmentDate;
  final Map<String, dynamic> details;
  final String? legacyEscalation;
  final String? attachmentPath;
  final String? attachmentUrl;

  String? get escalation =>
      checklistJsonNullableString(details['escalation']) ??
      checklistJsonNullableString(details['escalation_target']) ??
      legacyEscalation;

  factory ChecklistResponseData.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'response');
    return ChecklistResponseData(
      itemId: checklistJsonNullableInt(data['item_id']),
      itemKey: checklistJsonNullableString(data['item_key']),
      status: checklistJsonNullableString(data['status']),
      remark: checklistJsonNullableString(data['remark']),
      finding: checklistJsonNullableString(data['finding']),
      actionPlan: checklistJsonNullableString(data['action_plan']),
      commitmentDate: checklistJsonNullableString(data['commitment_date']),
      details: checklistJsonOptionalMap(data['details']),
      legacyEscalation:
          checklistJsonNullableString(data['escalation']) ??
          checklistJsonNullableString(data['escalation_target']),
      attachmentPath: checklistJsonNullableString(data['attachment_path']),
      attachmentUrl: checklistJsonNullableString(data['attachment_url']),
    );
  }
}

class ChecklistLoadResult {
  const ChecklistLoadResult({required this.template, required this.submission});

  final ChecklistTemplateData template;
  final ChecklistSubmissionData? submission;

  factory ChecklistLoadResult.fromJson(Object? value) {
    final data = checklistJsonMap(value, label: 'checklist response');
    return ChecklistLoadResult(
      template: ChecklistTemplateData.fromJson(data['template']),
      submission: data['submission'] == null
          ? null
          : ChecklistSubmissionData.fromJson(data['submission']),
    );
  }
}

Map<String, dynamic> checklistJsonMap(Object? value, {required String label}) {
  if (value is! Map) {
    throw FormatException('Server returned invalid $label data.');
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

Map<String, dynamic> checklistJsonOptionalMap(Object? value) {
  if (value == null) return const {};
  return checklistJsonMap(value, label: 'JSON');
}

String checklistJsonString(Object? value, {required String label}) {
  if (value is String) return value;
  throw FormatException('Server returned an invalid $label value.');
}

String? checklistJsonNullableString(Object? value) {
  return value is String ? value : null;
}

int checklistJsonInt(Object? value, {required String label}) {
  final result = checklistJsonNullableInt(value);
  if (result != null) return result;
  throw FormatException('Server returned an invalid $label value.');
}

int? checklistJsonNullableInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? checklistJsonNullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
