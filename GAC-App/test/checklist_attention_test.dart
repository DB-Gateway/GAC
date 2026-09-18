import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/checklist_models.dart';
import 'package:gac_flutter/utils/checklist_attention.dart';

void main() {
  const admin = AuthenticatedUser(
    id: 1,
    name: 'Admin',
    email: 'admin@example.com',
    userType: 'ADMIN',
    accountStatus: 'active',
  );

  test(
    'current NO and N/A answers count, regardless of historical metadata',
    () {
      final record = _record([
        _response(
          'yes',
          details: {
            'status': 'no',
            'choice': 'no',
            'has_issue': true,
            'flagged': true,
            'escalation': 'general_manager',
            'subform_answers': {'old': 'no'},
          },
        ),
        _response('na'),
        _response(null),
        _response(' NO '),
      ]);
      final targets = checklistAttentionTargets(record, admin);
      expect(targets.map((t) => t.itemKey), ['q1', 'q3']);
    },
  );

  test(
    'hourly review uses active configured slots instead of aggregate status',
    () {
      final record = _record(
        [
          _response(
            'no',
            details: {
              'slots': {'08:00': 'good'},
            },
          ),
          _response(
            'yes',
            details: {
              'slots': {
                '08:00': 'good',
                '09:00': 'not_good',
                '10:00': 'not_good',
                'unknown': 'not_good',
              },
            },
          ),
        ],
        mode: 'time_slots',
        metadata: {
          'active_slots': ['08:00', '09:00'],
        },
      );
      final targets = checklistAttentionTargets(record, admin);
      expect(targets, hasLength(1));
      expect(targets.single.itemKey, 'q1');
      expect(targets.single.slotKey, '09:00');
    },
  );

  test('documentation points to the specific negative customer answer', () {
    final record = _record([
      _response(
        'no',
        details: {
          'customers': [
            {
              'customer_index': 1,
              'answers': {'q0': 'yes', 'q1': 'yes'},
            },
            {
              'customer_index': 2,
              'answers': {'q0': 'yes', 'q1': 'no'},
            },
          ],
        },
      ),
      _response('no'),
    ], mode: 'dos_documentation');
    final targets = checklistAttentionTargets(record, admin);
    expect(targets, hasLength(1));
    expect(targets.single.itemKey, 'q1');
    expect(targets.single.customerIndex, 2);
  });

  test('DOS excludes answers assigned to another checker', () {
    const user = AuthenticatedUser(
      id: 2,
      name: 'Service',
      email: 'ce@gateway.com',
      userType: 'CE SERVICE',
      accountStatus: 'active',
    );
    final record = _record(
      [_response('no')],
      mode: 'dos',
      metadata: {'checker': 'PARTS'},
    );
    expect(checklistAttentionTargets(record, user), isEmpty);
    expect(checklistAttentionTargets(record, admin), hasLength(1));
  });

  test('orphan response keys cannot become links to unrelated questions', () {
    final record = _record([_response('no')], responsePrefix: 'removed');
    expect(checklistAttentionTargets(record, admin), isEmpty);
  });
}

ChecklistResponseData _response(
  String? status, {
  Map<String, dynamic> details = const {},
}) => ChecklistResponseData(
  itemId: null,
  itemKey: null,
  status: status,
  remark: 'Old remark',
  finding: 'Old finding',
  actionPlan: 'Old action',
  commitmentDate: null,
  details: details,
);

ChecklistLoadResult _record(
  List<ChecklistResponseData> responses, {
  String mode = 'yes_no_na',
  Map<String, dynamic> metadata = const {},
  String responsePrefix = 'q',
}) => ChecklistLoadResult(
  template: ChecklistTemplateData(
    id: 1,
    slug: 'test',
    name: 'Test',
    description: null,
    version: 1,
    settings: {
      'validation_mode': mode,
      'time_slots': [
        {'key': '08:00', 'label': '8 AM'},
        {'key': '09:00', 'label': '9 AM'},
        {'key': '10:00', 'label': '10 AM'},
      ],
    },
    sections: [
      ChecklistSectionData(
        id: 1,
        key: 'section',
        title: 'Section',
        sortOrder: 0,
        metadata: const {},
        items: [
          for (var i = 0; i < responses.length; i++)
            ChecklistItemData(
              id: i,
              key: 'q$i',
              prompt: 'Question $i',
              sortOrder: i,
              metadata: metadata,
            ),
        ],
      ),
    ],
  ),
  submission: ChecklistSubmissionData(
    id: 1,
    status: 'draft',
    auditDate: '2026-09-02',
    templateVersion: 1,
    scores: const {'no': 99},
    issueCount: 99,
    responses: {
      for (var i = 0; i < responses.length; i++)
        '$responsePrefix$i': responses[i],
    },
    answeredItems: responses.length,
    totalItems: responses.length,
    completionPercentage: 100,
    submittedAt: null,
  ),
);
