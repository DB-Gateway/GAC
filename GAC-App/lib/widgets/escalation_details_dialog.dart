import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/authenticated_user.dart';
import '../models/escalation_follow_up.dart';
import '../models/user_notification.dart';
import '../services/escalation_follow_up_service.dart';
import '../theme/gac_theme.dart';
import 'escalation_follow_up_sheet.dart';

Future<EscalationFollowUp?> showEscalationDetailsDialog(
  BuildContext context,
  UserNotification notification, {
  EscalationFollowUpRepository? followUpRepository,
  ImagePicker? imagePicker,
  ValueChanged<EscalationFollowUp>? onFollowUpSubmitted,
  bool? canFollowUp,
  AuthenticatedUser? currentUser,
}) => showModalBottomSheet<EscalationFollowUp>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  constraints: const BoxConstraints(maxWidth: 604),
  builder: (context) => EscalationDetailsDialog(
    notification: notification,
    followUpRepository: followUpRepository,
    imagePicker: imagePicker,
    onFollowUpSubmitted: onFollowUpSubmitted,
    canFollowUp: canFollowUp,
    currentUser: currentUser,
  ),
);

class EscalationDetailsDialog extends StatefulWidget {
  const EscalationDetailsDialog({
    required this.notification,
    this.followUpRepository,
    this.imagePicker,
    this.onFollowUpSubmitted,
    this.canFollowUp,
    this.currentUser,
    super.key,
  });

  final UserNotification notification;
  final EscalationFollowUpRepository? followUpRepository;
  final ImagePicker? imagePicker;
  final ValueChanged<EscalationFollowUp>? onFollowUpSubmitted;
  final bool? canFollowUp;
  final AuthenticatedUser? currentUser;

  @override
  State<EscalationDetailsDialog> createState() =>
      _EscalationDetailsDialogState();
}

class _EscalationDetailsDialogState extends State<EscalationDetailsDialog> {
  EscalationFollowUp? _latestFollowUp;
  late bool _canFollowUp;

  @override
  void initState() {
    super.initState();
    if (widget.canFollowUp != null) {
      _canFollowUp = widget.canFollowUp!;
    } else if (widget.currentUser != null) {
      _canFollowUp = widget.currentUser!.isUtility;
    } else {
      _canFollowUp = true;
      _loadCachedUserRole();
    }
  }

  Future<void> _loadCachedUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(gacAuthUserKey);
      if (userJson != null && userJson.isNotEmpty && mounted) {
        final user = AuthenticatedUser.fromJson(jsonDecode(userJson));
        setState(() {
          _canFollowUp = user.isUtility;
        });
      }
    } catch (_) {}
  }

  Future<void> _followUp() async {
    if (!_canFollowUp) return;
    final result = await showModalBottomSheet<EscalationFollowUp>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 604),
      builder: (_) => EscalationFollowUpSheet(
        notification: widget.notification,
        repository: widget.followUpRepository,
        imagePicker: widget.imagePicker,
      ),
    );
    if (result != null && mounted) {
      setState(() => _latestFollowUp = result);
      widget.onFollowUpSubmitted?.call(result);
    }
  }

  static String _formatAnswer(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'no') return 'NO';
    if (lower == 'yes') return 'YES';
    if (lower == 'na' || lower == 'n/a' || lower == 'n_a') return 'N/A';
    return raw.trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.notification.data;
    final bool isAlreadyFollowedUp =
        _latestFollowUp != null || widget.notification.isFollowedUp;
    final String followUpMessage;
    if (_latestFollowUp != null) {
      followUpMessage = 'Follow-up sent to ${_latestFollowUp!.recipientName}.';
    } else if (data['follow_up_recipient_name'] != null &&
        data['follow_up_recipient_name'].toString().trim().isNotEmpty) {
      followUpMessage =
          'Follow-up already sent to ${data['follow_up_recipient_name']}.';
    } else {
      followUpMessage = 'Follow-up already completed for this finding.';
    }
    final rawAttachment = (data['attachment_url'] ??
            data['attachment'] ??
            data['attachment_path'])
        ?.toString()
        .trim();
    final normalizedAttachment = rawAttachment != null &&
            rawAttachment.isNotEmpty &&
            !rawAttachment.startsWith('http://') &&
            !rawAttachment.startsWith('https://') &&
            !rawAttachment.startsWith('/storage') &&
            !rawAttachment.startsWith('storage/')
        ? '/storage/$rawAttachment'
        : rawAttachment;
    final attachmentUrl = resolveGacAssetUrl(normalizedAttachment);
    String value(String key) => data[key]?.toString().trim() ?? '';
    final sections = [
      (
        title: 'Checklist details',
        fields: [
          _Detail(
            'Checklist',
            value('template_name'),
            Icons.fact_check_outlined,
          ),
          _Detail('Branch', value('branch'), Icons.location_on_outlined),
          _Detail('Audit date', value('audit_date'), Icons.event_outlined),
          _Detail('Checklist item', value('item_key'), Icons.tag_rounded),
        ],
      ),
      (
        title: 'Reported issue',
        fields: [
          _Detail('Question', value('question'), Icons.help_outline_rounded),
          if (value('status').isNotEmpty || value('answer').isNotEmpty)
            _Detail(
              'Checklist answer',
              _formatAnswer(
                value('status').isNotEmpty
                    ? value('status')
                    : value('answer'),
              ),
              Icons.fact_check_outlined,
              accent: (value('status').isNotEmpty
                          ? value('status')
                          : value('answer'))
                      .toLowerCase() ==
                  'no'
                  ? GacColors.red200
                  : GacColors.green200,
            ),
          _Detail(
            'Finding',
            value('finding'),
            Icons.report_problem_outlined,
            accent: GacColors.amber200,
          ),
        ],
      ),
      (
        title: 'Follow-up details',
        fields: [
          _Detail(
            'Escalated to',
            value('escalation_target_label').isNotEmpty
                ? value('escalation_target_label')
                : value('escalation_target'),
            Icons.groups_outlined,
          ),
          _Detail(
            'Commitment date',
            value('commitment_date'),
            Icons.event_available_outlined,
          ),
          _Detail(
            'Action to take',
            value('action_plan'),
            Icons.assignment_outlined,
            accent: GacColors.green200,
          ),
          _Detail('Escalated by', value('sender_name'), Icons.person_outline),
        ],
      ),
    ];
    final visibleSections = [
      for (final section in sections)
        if (section.fields.any((field) => field.value.isNotEmpty))
          (
            title: section.title,
            fields: section.fields
                .where((field) => field.value.isNotEmpty)
                .toList(),
          ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_latestFollowUp);
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Material(
            key: const ValueKey('escalation-details-dialog'),
            color: GacColors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            key: const ValueKey('escalation-details-drag-handle'),
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: GacColors.navy700,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: const Text(
                                      'Checklist escalation',
                                      style: TextStyle(
                                        color: GacColors.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Review the finding and follow-up information.',
                                    style: TextStyle(
                                      color: GacColors.textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () =>
                                  Navigator.of(context).pop(_latestFollowUp),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: GacColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1, color: GacColors.cardBorder),
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey('escalation-details-scroll'),
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final section in visibleSections)
                          _DetailSection(
                            title: section.title,
                            fields: section.fields,
                          ),
                        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: const Text(
                                    'Checklist attachment',
                                    style: TextStyle(
                                      color: GacColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: GacColors.offWhite,
                                      border: Border.all(
                                        color: GacColors.cardBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Image.network(
                                      attachmentUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        height: 70,
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_outlined,
                                              size: 18,
                                              color: GacColors.textMuted,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Attachment unavailable',
                                              style: TextStyle(
                                                color: GacColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (visibleSections.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'No escalation details were included in this notification.',
                              style: TextStyle(
                                color: GacColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: GacColors.cardBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isAlreadyFollowedUp) ...[
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            key: const ValueKey('escalation-follow-up-done-banner'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: GacColors.green200.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: GacColors.green200.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: GacColors.green200,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    followUpMessage,
                                    style: const TextStyle(
                                      color: GacColors.green200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          key: const ValueKey('escalation-details-close'),
                          onPressed: () =>
                              Navigator.of(context).pop(_latestFollowUp),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            backgroundColor: GacColors.navy800,
                            foregroundColor: GacColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: GacColors.cardBorder),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ] else if (_canFollowUp) ...[
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(_latestFollowUp),
                              child: const Text('Close'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                key: const ValueKey('escalation-follow-up'),
                                onPressed: _followUp,
                                icon: const Icon(Icons.reply_rounded, size: 20),
                                label: const Text('Follow-up'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  backgroundColor: GacColors.primary,
                                  foregroundColor: GacColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Semantics(
                          child: Container(
                            key: const ValueKey('escalation-utility-only-banner'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: GacColors.navy700.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: GacColors.cardBorder,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: GacColors.textSecondary,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Only utility personnel can submit a follow-up for this escalation.',
                                    style: TextStyle(
                                      color: GacColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          key: const ValueKey('escalation-details-close'),
                          onPressed: () =>
                              Navigator.of(context).pop(_latestFollowUp),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            backgroundColor: GacColors.navy800,
                            foregroundColor: GacColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: GacColors.cardBorder),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _Detail {
  const _Detail(
    this.label,
    this.value,
    this.icon, {
    this.accent = const Color(0xFF9CC2FF),
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.fields});

  final String title;
  final List<_Detail> fields;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: GacColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: GacColors.offWhite,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: GacColors.cardBorder),
          ),
          child: Column(
            children: [
              for (var index = 0; index < fields.length; index++) ...[
                if (index > 0)
                  const Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: GacColors.cardBorder,
                  ),
                _DetailRow(detail: fields[index]),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final _Detail detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: detail.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(detail.icon, size: 20, color: detail.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.label,
                style: const TextStyle(
                  color: GacColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                detail.value,
                style: const TextStyle(
                  color: GacColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
