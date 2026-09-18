import 'dart:typed_data';

enum EscalationRemark {
  inProgress('in_progress', 'Corrective action in progress'),
  awaitingApproval('awaiting_approval', 'Awaiting approval or budget'),
  awaitingMaterials(
    'awaiting_materials',
    'Awaiting supplies or replacement parts',
  ),
  repairScheduled('repair_scheduled', 'Repair or maintenance scheduled'),
  cleaningCompleted('cleaning_completed', 'Cleaning or organization completed'),
  recordsUpdating('records_updating', 'Documents or records being updated'),
  trainingScheduled(
    'training_scheduled',
    'Staff briefing or training scheduled',
  ),
  awaitingIt('awaiting_it', 'Awaiting IT or system access support'),
  readyForVerification(
    'ready_for_verification',
    'Completed; ready for verification',
  ),
  others('others', 'Others');

  const EscalationRemark(this.code, this.label);

  final String code;
  final String label;
}

class FollowUpPhoto {
  const FollowUpPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

class EscalationFollowUp {
  const EscalationFollowUp({
    required this.id,
    required this.remarks,
    required this.recipientName,
    required this.createdAt,
  });

  final int id;
  final String remarks;
  final String recipientName;
  final DateTime createdAt;

  factory EscalationFollowUp.fromJson(Object? value) {
    if (value is! Map ||
        value['id'] is! int ||
        value['remarks'] is! String ||
        value['recipient_name'] is! String ||
        value['created_at'] is! String) {
      throw const FormatException('Server returned an invalid follow-up.');
    }
    final createdAt = DateTime.tryParse(value['created_at'] as String);
    if (createdAt == null) {
      throw const FormatException('Server returned an invalid follow-up date.');
    }
    return EscalationFollowUp(
      id: value['id'] as int,
      remarks: value['remarks'] as String,
      recipientName: value['recipient_name'] as String,
      createdAt: createdAt,
    );
  }
}
