import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../models/escalation_follow_up.dart';
import '../models/user_notification.dart';
import '../services/escalation_follow_up_service.dart';
import '../theme/gac_theme.dart';

class EscalationFollowUpSheet extends StatefulWidget {
  const EscalationFollowUpSheet({
    required this.notification,
    this.repository,
    this.imagePicker,
    super.key,
  });

  final UserNotification notification;
  final EscalationFollowUpRepository? repository;
  final ImagePicker? imagePicker;

  @override
  State<EscalationFollowUpSheet> createState() =>
      _EscalationFollowUpSheetState();
}

class _EscalationFollowUpSheetState extends State<EscalationFollowUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _remarksKey = GlobalKey<FormFieldState<String>>();
  final _optionKey = GlobalKey<FormFieldState<EscalationRemark>>();
  final _remarks = TextEditingController();
  final _photos = <FollowUpPhoto>[];
  late final _repository = widget.repository ?? EscalationFollowUpApiService();
  // Keep the same identifier on a network retry to avoid duplicate updates.
  late final _requestId = List.generate(
    16,
    (_) => Random.secure().nextInt(256),
  ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  EscalationRemark? _selectedRemark;
  bool _sending = false;
  bool _takingPhoto = false;
  String? _error;

  bool get _busy => _sending || _takingPhoto;

  @override
  void dispose() {
    _remarks.dispose();
    if (widget.repository == null) {
      (_repository as EscalationFollowUpApiService).dispose();
    }
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_busy || _photos.length >= maxFollowUpPhotos) return;
    setState(() {
      _takingPhoto = true;
      _error = null;
    });
    try {
      final photo = await (widget.imagePicker ?? ImagePicker()).pickImage(
        source: ImageSource.camera,
        maxWidth: 1440,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > maxFollowUpPhotoBytes) {
        setState(() => _error = 'Use a photo smaller than 10 MB.');
        return;
      }
      setState(
        () => _photos.add(FollowUpPhoto(bytes: bytes, filename: photo.name)),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not access the camera. Check camera permission and try again. You can also send without a photo.',
        );
      }
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (widget.notification.isFollowedUp) {
      setState(() => _error = 'A follow-up has already been submitted for this escalation.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      final fieldContext = _selectedRemark == null
          ? _optionKey.currentContext
          : _remarksKey.currentContext;
      if (fieldContext != null) {
        await Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 200),
        );
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await _repository.submit(
        notification: widget.notification,
        requestId: _requestId,
        remark: _selectedRemark!,
        otherRemarks: _selectedRemark == EscalationRemark.others
            ? _remarks.text.trim()
            : '',
        photos: List.unmodifiable(_photos),
      );
      if (mounted) Navigator.of(context).pop(result);
    } on EscalationFollowUpException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The follow-up could not be sent. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openAttachmentViewer(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: GacColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GacColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Failed to load attachment image.',
                        style: TextStyle(color: GacColors.red200),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                ),
                tooltip: 'Close image',
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: GacColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAnswer(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'no') return 'NO';
    if (lower == 'yes') return 'YES';
    if (lower == 'na' || lower == 'n/a' || lower == 'n_a') return 'N/A';
    return raw.trim().toUpperCase();
  }

  static Color _answerBadgeBg(String answer) {
    final lower = answer.toLowerCase();
    if (lower == 'no') return const Color(0x2EE71D48);
    if (lower == 'yes') return const Color(0x26249D6B);
    return const Color(0x2E2979FF);
  }

  static Color _answerBadgeBorder(String answer) {
    final lower = answer.toLowerCase();
    if (lower == 'no') return GacColors.error.withValues(alpha: 0.4);
    if (lower == 'yes') return GacColors.success.withValues(alpha: 0.4);
    return GacColors.primary.withValues(alpha: 0.4);
  }

  static Color _answerTextColor(String answer) {
    final lower = answer.toLowerCase();
    if (lower == 'no') return GacColors.red200;
    if (lower == 'yes') return GacColors.green200;
    return GacColors.cyan;
  }

  static IconData _answerIcon(String answer) {
    final lower = answer.toLowerCase();
    if (lower == 'no') return Icons.cancel_outlined;
    if (lower == 'yes') return Icons.check_circle_outline_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.notification.data;
    final question = data['question']?.toString().trim() ?? '';
    final manager = data['sender_name']?.toString().trim() ?? '';
    final rawAnswer = (data['status'] ??
            data['answer'] ??
            data['checklist_answer'])
        ?.toString()
        .trim() ??
        '';
    final answerLabel = _formatAnswer(rawAnswer);
    final finding =
        (data['finding'] ?? data['remark'])?.toString().trim() ?? '';
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
    final hasChecklistInfo = question.isNotEmpty ||
        answerLabel.isNotEmpty ||
        finding.isNotEmpty ||
        (attachmentUrl != null && attachmentUrl.isNotEmpty);
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Material(
            key: const ValueKey('escalation-follow-up-sheet'),
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
                    padding: const EdgeInsets.fromLTRB(22, 16, 14, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          color: GacColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Follow-up',
                            style: TextStyle(
                              color: GacColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cancel follow-up',
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: GacColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: GacColors.cardBorder),
                  Flexible(
                    child: SingleChildScrollView(
                      key: const ValueKey('escalation-follow-up-scroll'),
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              manager.isEmpty
                                  ? 'Send an update to the manager who escalated this finding.'
                                  : 'Send an update to $manager.',
                              style: const TextStyle(
                                color: GacColors.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            if (hasChecklistInfo) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: GacColors.offWhite,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: GacColors.cardBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Checklist question',
                                                style: TextStyle(
                                                  color:
                                                      GacColors.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (question.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  question,
                                                  style: const TextStyle(
                                                    color:
                                                        GacColors.textPrimary,
                                                    fontSize: 13,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (answerLabel.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _answerBadgeBg(
                                                answerLabel,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _answerBadgeBorder(
                                                  answerLabel,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _answerIcon(answerLabel),
                                                  size: 13,
                                                  color: _answerTextColor(
                                                    answerLabel,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  answerLabel,
                                                  style: TextStyle(
                                                    color: _answerTextColor(
                                                      answerLabel,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (finding.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: GacColors.cardSurface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: GacColors.cardBorder,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.report_problem_outlined,
                                              size: 15,
                                              color: GacColors.amber200,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Reported finding',
                                                    style: TextStyle(
                                                      color:
                                                          GacColors
                                                              .textSecondary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    finding,
                                                    style: const TextStyle(
                                                      color: GacColors.amber200,
                                                      fontSize: 12,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (attachmentUrl != null &&
                                        attachmentUrl.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.attach_file_rounded,
                                            size: 14,
                                            color: GacColors.textSecondary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Attachment',
                                            style: TextStyle(
                                              color:
                                                  GacColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _openAttachmentViewer(
                                          attachmentUrl,
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                width: double.infinity,
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 180,
                                                    ),
                                                color: GacColors.cardSurface,
                                                child: Image.network(
                                                  attachmentUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    progress,
                                                  ) {
                                                    if (progress == null) {
                                                      return child;
                                                    }
                                                    return const SizedBox(
                                                      height: 100,
                                                      child: Center(
                                                        child: SizedBox.square(
                                                          dimension: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (
                                                    _,
                                                    _,
                                                    _,
                                                  ) => Container(
                                                    height: 60,
                                                    alignment:
                                                        Alignment.center,
                                                    child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          size: 18,
                                                          color:
                                                              GacColors
                                                                  .textMuted,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Attachment unavailable',
                                                          style: TextStyle(
                                                            color:
                                                                GacColors
                                                                    .textMuted,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.65),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.fullscreen_rounded,
                                                      size: 14,
                                                      color: GacColors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Tap to enlarge',
                                                      style: TextStyle(
                                                        color: GacColors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text(
                              'Remarks *',
                              style: TextStyle(
                                color: GacColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Choose the update that applies to this finding.',
                              style: TextStyle(
                                color: GacColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<EscalationRemark>(
                              key: _optionKey,
                              initialValue: _selectedRemark,
                              isExpanded: true,
                              isDense: false,
                              borderRadius: BorderRadius.circular(15),
                              menuMaxHeight: 360,
                              dropdownColor: GacColors.offWhite,
                              style: const TextStyle(
                                color: GacColors.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Select a remark',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.comment_outlined,
                                  color: GacColors.textSecondary,
                                ),
                              ),
                              selectedItemBuilder: (context) => [
                                for (final option in EscalationRemark.values)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      option.label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: GacColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                              items: [
                                for (final option in EscalationRemark.values)
                                  DropdownMenuItem(
                                    value: option,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        option.label,
                                        style: TextStyle(
                                          color: option == _selectedRemark
                                              ? GacColors.cyan
                                              : GacColors.textPrimary,
                                          fontWeight:
                                              option == _selectedRemark
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) =>
                                        setState(() => _selectedRemark = value),
                              validator: (value) => value == null
                                  ? 'Choose a remark to continue.'
                                  : null,
                            ),
                            if (_selectedRemark == EscalationRemark.others) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                key: _remarksKey,
                                controller: _remarks,
                                enabled: !_busy,
                                minLines: 3,
                                maxLines: 5,
                                maxLength: maxFollowUpRemarksLength,
                                style: const TextStyle(
                                  color: GacColors.textPrimary,
                                  fontSize: 14,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Your remarks *',
                                  hintText: 'Describe the progress, delay, or action taken.',
                                  alignLabelWithHint: true,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Enter your follow-up remarks.'
                                    : null,
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text(
                              'Photos (optional)',
                              style: TextStyle(
                                color: GacColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Take up to 3 photos to show the current condition or work completed.',
                              style: TextStyle(
                                color: GacColors.textSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_photos.isNotEmpty) ...[
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (
                                    var index = 0;
                                    index < _photos.length;
                                    index++
                                  )
                                    SizedBox(
                                      width: 96,
                                      height: 106,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.memory(
                                              _photos[index].bytes,
                                              fit: BoxFit.cover,
                                              semanticLabel:
                                                  'Follow-up photo ${index + 1}',
                                              errorBuilder: (_, _, _) =>
                                                  const ColoredBox(
                                                    color: GacColors.offWhite,
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton.filled(
                                              tooltip:
                                                  'Remove photo ${index + 1}',
                                              onPressed: _busy
                                                  ? null
                                                  : () => setState(
                                                      () => _photos.removeAt(
                                                        index,
                                                      ),
                                                    ),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            OutlinedButton.icon(
                              key: const ValueKey('follow-up-take-photo'),
                              onPressed:
                                  _busy || _photos.length >= maxFollowUpPhotos
                                  ? null
                                  : _takePhoto,
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: Text(
                                _takingPhoto
                                    ? 'Opening camera…'
                                    : 'Take a photo',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: GacColors.cardBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: GacColors.red200,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FilledButton.icon(
                          key: const ValueKey('send-escalation-follow-up'),
                          onPressed: _busy ? null : _submit,
                          icon: _sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(_sending ? 'Sending…' : 'Send follow-up'),
                        ),
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
