import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin/admin_destination.dart';
import '../data/admin_data.dart';
import '../services/share_service.dart';
import '../theme/gac_theme.dart';
import 'admin_page.dart';
import 'admin_ui.dart';

class AdminChecklistEditor extends StatefulWidget {
  const AdminChecklistEditor({
    required this.module,
    required this.onNavigate,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.presetName,
    required this.presetCount,
    required this.coverageCount,
    required this.initialTemplate,
    this.topContent,
    this.onShare,
    super.key,
  }) : assert(
         module == AdminDestination.dos || module == AdminDestination.fiveS,
       );

  final AdminDestination module;
  final AdminNavigationCallback onNavigate;
  final String eyebrow;
  final String title;
  final String description;
  final String presetName;
  final int presetCount;
  final int coverageCount;
  final List<ChecklistSection> initialTemplate;
  final Widget? topContent;
  final ShareTextCallback? onShare;

  @override
  State<AdminChecklistEditor> createState() => _AdminChecklistEditorState();
}

class _AdminChecklistEditorState extends State<AdminChecklistEditor> {
  static const _responses = <String>['YES', 'NO', 'N/A'];
  static const _levels = <String>['Basic', 'Standard', 'Beyond'];

  late List<ChecklistSection> _savedTemplate;
  late List<ChecklistSection> _sections;
  final _searchController = TextEditingController();
  final Map<String, String> _remarks = <String, String>{};
  String _search = '';
  bool _editMode = false;
  int _editorRevision = 0;
  int _remarksRevision = 0;

  bool get _isDos => widget.module == AdminDestination.dos;
  String get _moduleName => _isDos ? 'DOS' : '5S';

  List<ChecklistItem> get _allItems => [
    for (final section in _sections) ...section.items,
  ];

  int get _answered => _allItems.where((item) => item.response != null).length;
  int get _yesCount => _allItems.where((item) => item.response == 'YES').length;
  int get _noCount => _allItems.where((item) => item.response == 'NO').length;
  int get _naCount => _allItems.where((item) => item.response == 'N/A').length;

  int get _score {
    final applicable = _yesCount + _noCount;
    return applicable == 0 ? 0 : ((_yesCount / applicable) * 100).round();
  }

  int get _completion =>
      ((_answered / math.max(1, _allItems.length)) * 100).round();

  List<ChecklistSection> get _visibleSections {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _sections;

    return [
      for (final section in _sections)
        if (section.items
                .where(
                  (item) =>
                      '${section.title} ${item.subject ?? ''} ${item.text}'
                          .toLowerCase()
                          .contains(query),
                )
                .toList()
            case final matchingItems when matchingItems.isNotEmpty)
          section.copyWith(items: matchingItems),
    ];
  }

  @override
  void initState() {
    super.initState();
    _savedTemplate = _cloneTemplate(widget.initialTemplate);
    _sections = _cloneTemplate(widget.initialTemplate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChecklistSection> _cloneTemplate(List<ChecklistSection> template) {
    return [
      for (final section in template)
        section.copyWith(
          items: [for (final item in section.items) item.copyWith()],
        ),
    ];
  }

  void _updateItem(
    String sectionId,
    String itemId,
    ChecklistItem Function(ChecklistItem item) transform,
  ) {
    setState(() {
      _sections = [
        for (final section in _sections)
          if (section.id == sectionId)
            section.copyWith(
              items: [
                for (final item in section.items)
                  if (item.id == itemId) transform(item) else item,
              ],
            )
          else
            section,
      ];
    });
  }

  void _updateSection(String sectionId, String title) {
    setState(() {
      _sections = [
        for (final section in _sections)
          section.id == sectionId ? section.copyWith(title: title) : section,
      ];
    });
  }

  void _addItem(String sectionId) {
    final itemId =
        '${_moduleName.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _sections = [
        for (final section in _sections)
          if (section.id == sectionId)
            section.copyWith(
              items: [
                ...section.items,
                ChecklistItem(
                  id: itemId,
                  text: 'New checklist item',
                  subject: _isDos ? 'New Standard' : null,
                  level: _isDos ? 'Standard' : null,
                ),
              ],
            )
          else
            section,
      ];
    });
  }

  Future<void> _removeItem(String sectionId, String itemId) async {
    final remove = await _showConfirmation(
      title: 'Remove item?',
      message: 'This removes the item from the working preset.',
      confirmLabel: 'Remove',
    );
    if (!mounted || !remove) return;

    setState(() {
      _sections = [
        for (final section in _sections)
          if (section.id == sectionId)
            section.copyWith(
              items: section.items.where((item) => item.id != itemId).toList(),
            )
          else
            section,
      ];
    });
  }

  void _addSection() {
    setState(() {
      _sections = [
        ..._sections,
        ChecklistSection(
          id: 'section-${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Checklist Section',
          items: const [],
        ),
      ];
    });
  }

  void _beginEdit() {
    setState(() {
      _sections = _cloneTemplate(_savedTemplate);
      _editMode = true;
      _editorRevision++;
    });
  }

  void _cancelEdit() {
    setState(() {
      _sections = _cloneTemplate(_savedTemplate);
      _editMode = false;
      _editorRevision++;
    });
  }

  Future<void> _savePreset() async {
    final hasBlank = _sections.any(
      (section) =>
          section.title.trim().isEmpty ||
          section.items.any((item) => item.text.trim().isEmpty),
    );

    if (hasBlank) {
      await _showMessage(
        title: 'Complete the preset',
        message: 'Every coverage area and checklist item needs a title.',
      );
      return;
    }

    setState(() {
      _savedTemplate = _cloneTemplate(_sections);
      _editMode = false;
      _editorRevision++;
    });
    await _showMessage(
      title: 'Master preset saved',
      message: '${widget.title} has been updated on this device.',
    );
  }

  Future<void> _restorePreset() async {
    final restore = await _showConfirmation(
      title: 'Restore original preset?',
      message: 'Your unsaved master-form edits will be replaced.',
      confirmLabel: 'Restore',
    );
    if (!mounted || !restore) return;

    setState(() {
      _sections = _cloneTemplate(widget.initialTemplate);
      _savedTemplate = _cloneTemplate(widget.initialTemplate);
      _editorRevision++;
    });
  }

  void _resetResponses() {
    setState(() {
      _sections = [
        for (final section in _sections)
          section.copyWith(
            items: [
              for (final item in section.items)
                item.copyWith(clearResponse: true),
            ],
          ),
      ];
      _remarks.clear();
      _remarksRevision++;
    });
  }

  Future<void> _submitAudit() async {
    if (_answered != _allItems.length) {
      final remaining = _allItems.length - _answered;
      await _showMessage(
        title: 'Checklist is incomplete',
        message:
            '$remaining displayed item${remaining == 1 ? ' is' : 's are'} '
            'still unanswered.',
      );
      return;
    }

    await _showMessage(
      title: _isDos ? 'DOS audit submitted' : '5S checklist submitted',
      message: 'Score: $_score% · Findings: ${_noCount + _naCount}',
    );
  }

  Future<void> _shareSummary() async {
    final message =
        '${widget.title}\n'
        'Score: $_score%\n'
        'Completion: $_completion%\n'
        'Findings: ${_noCount + _naCount}';
    final onShare = widget.onShare;
    if (onShare != null) {
      await onShare(message);
      return;
    }
    if (!mounted) return;
    await shareText(context, message);
  }

  Future<void> _showMessage({required String title, required String message}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmation({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: GacColors.error),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = _visibleSections;
    return AdminPage(
      onNavigate: widget.onNavigate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.topContent != null) widget.topContent!,
          AdminPageHeading(
            eyebrow: widget.eyebrow,
            title: widget.title,
            description: widget.description,
            action: AdminActionButton(
              label: 'Share Summary',
              icon: Icons.share_outlined,
              compact: true,
              onPressed: () => unawaited(_shareSummary()),
            ),
          ),
          _buildTopActions(),
          _buildMetricGrid(),
          _buildAuditDetails(),
          _buildRulesCard(),
          const SizedBox(height: 28),
          AdminSectionHeading(
            eyebrow: _editMode ? 'Template editor' : 'Audit mode',
            title: widget.presetName,
            detail: _editMode
                ? 'Edit section names and checklist wording, then save the master preset.'
                : '${visibleSections.length} representative sections are shown in this mobile prototype.',
            action: AdminStatusPill(
              label: _editMode ? 'Editing' : 'Audit mode',
              tone: _editMode ? AdminStatusTone.warning : AdminStatusTone.dark,
            ),
          ),
          _buildSearchBox(),
          const SizedBox(height: 13),
          if (visibleSections.isEmpty)
            _buildEmptyCard()
          else
            for (var index = 0; index < visibleSections.length; index++) ...[
              _buildChecklistSection(visibleSections[index], index),
              if (index < visibleSections.length - 1)
                const SizedBox(height: 12),
            ],
          const SizedBox(height: 17),
          _editMode ? _buildEditFooter() : _buildAuditFooter(),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          if (!_editMode)
            AdminActionButton(
              label: 'Edit Master Form',
              icon: Icons.edit_outlined,
              variant: AdminActionButtonVariant.primary,
              onPressed: _beginEdit,
            )
          else ...[
            AdminActionButton(label: 'Cancel', onPressed: _cancelEdit),
            AdminActionButton(
              label: 'Save Master Preset',
              icon: Icons.save_outlined,
              variant: AdminActionButtonVariant.primary,
              onPressed: () => unawaited(_savePreset()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    final compact = MediaQuery.sizeOf(context).width < 540;
    final widthFactor = compact ? 0.48 : 0.235;
    final cards = <Widget>[
      AdminMetricCard(
        label: _isDos ? 'Overall Audit Score' : 'Current Score',
        value: '$_score%',
        detail: 'YES ÷ applicable responses',
        progress: _score.toDouble(),
        icon: Icons.speed_rounded,
      ),
      AdminMetricCard(
        label: 'Completion',
        value: '$_completion%',
        detail: '$_answered / ${_allItems.length} displayed items',
        progress: _completion.toDouble(),
        icon: Icons.done_all_outlined,
      ),
      AdminMetricCard(
        label: 'Flagged Findings',
        value: '${_noCount + _naCount}',
        detail: '$_noCount NO · $_naCount N/A',
        icon: Icons.warning_amber_outlined,
      ),
      AdminMetricCard(
        label: 'Master Preset',
        value: '${widget.presetCount}',
        detail:
            '${widget.coverageCount} ${_isDos ? 'coverage areas' : 'sections'}',
        progress: 100,
        icon: Icons.layers_outlined,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(width: constraints.maxWidth * widthFactor, child: card),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditDetails() {
    const details = <(String, String)>[
      ('DEALER', 'Gateway Motors'),
      ('OUTLET / BRANCH', 'Pasong Tamo'),
      ('AUDIT DATE', 'August 10, 2026'),
      ('AUDITOR', 'General Manager'),
    ];
    return AdminSurfaceCard(
      margin: const EdgeInsets.only(bottom: 13),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final detail in details)
              SizedBox(
                width: constraints.maxWidth * 0.48,
                child: _buildDetailField(detail.$1, detail.$2),
              ),
            SizedBox(
              width: constraints.maxWidth,
              child: _buildDetailField('MASTER PRESET', widget.presetName),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 57),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GacColors.offWhite,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: GacColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: GacColors.gray,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: GacColors.black,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GacColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: GacColors.primary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: GacColors.navigation,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info, size: 17, color: GacColors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDos ? 'Main Form scoring rules' : '5S scoring rules',
                  style: const TextStyle(
                    color: GacColors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select YES, NO, or N/A for every item. N/A is excluded '
                  'from the score. NO and N/A require a finding or '
                  'corrective-action note.',
                  style: TextStyle(
                    color: GacColors.gray,
                    fontSize: 9,
                    height: 14 / 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      constraints: const BoxConstraints(minHeight: 47),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: GacColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GacColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: GacColors.gray),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              style: const TextStyle(color: GacColors.black, fontSize: 10),
              decoration: const InputDecoration(
                hintText: 'Search coverage area or checklist item...',
                hintStyle: TextStyle(color: GacColors.muted, fontSize: 10),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_search.isNotEmpty)
            Semantics(
              button: true,
              label: 'Clear checklist search',
              child: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.cancel, size: 19, color: GacColors.gray),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(ChecklistSection section, int sectionIndex) {
    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 67),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: GacColors.navigation,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GacColors.navy800,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: GacColors.navy700),
                  ),
                  child: Text(
                    '${sectionIndex + 1}',
                    style: const TextStyle(
                      color: GacColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_editMode)
                  Expanded(child: _buildSectionTitleField(section))
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: GacColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${section.items.length} displayed item'
                          '${section.items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: GacColors.muted,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          for (var index = 0; index < section.items.length; index++)
            _buildChecklistItem(
              section.id,
              section.items[index],
              index,
              showTopBorder: index > 0,
            ),
          if (_editMode) _buildAddItemButton(section.id),
        ],
      ),
    );
  }

  Widget _buildSectionTitleField(ChecklistSection section) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: TextFormField(
        key: ValueKey('section-title-${section.id}-$_editorRevision'),
        initialValue: section.title,
        onChanged: (value) => _updateSection(section.id, value),
        style: const TextStyle(
          color: GacColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'Coverage area',
          hintStyle: const TextStyle(color: GacColors.muted, fontSize: 12),
          filled: true,
          fillColor: GacColors.navy900,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: GacColors.navy700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: GacColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    String sectionId,
    ChecklistItem item,
    int itemIndex, {
    required bool showTopBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: showTopBorder
            ? const Border(top: BorderSide(color: GacColors.lightGray))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GacColors.offWhite,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: GacColors.border),
            ),
            child: Text(
              '${itemIndex + 1}',
              style: const TextStyle(
                color: GacColors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _editMode
                ? _buildEditableItem(sectionId, item)
                : _buildAuditItem(sectionId, item),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(String sectionId, ChecklistItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isDos) ...[
          _buildEditorField(
            key: ValueKey('subject-${item.id}-$_editorRevision'),
            initialValue: item.subject ?? '',
            hintText: 'Standard subject',
            fontWeight: FontWeight.w800,
            onChanged: (value) => _updateItem(
              sectionId,
              item.id,
              (current) => current.copyWith(subject: value),
            ),
          ),
          const SizedBox(height: 8),
          _buildLevelRow(sectionId, item),
          const SizedBox(height: 8),
        ],
        _buildEditorField(
          key: ValueKey('wording-${item.id}-$_editorRevision'),
          initialValue: item.text,
          hintText: 'Checklist wording',
          minHeight: 94,
          maxLines: null,
          onChanged: (value) => _updateItem(
            sectionId,
            item.id,
            (current) => current.copyWith(text: value),
          ),
        ),
        const SizedBox(height: 9),
        AdminActionButton(
          label: 'Remove Item',
          icon: Icons.delete_outline,
          compact: true,
          variant: AdminActionButtonVariant.danger,
          onPressed: () => unawaited(_removeItem(sectionId, item.id)),
        ),
      ],
    );
  }

  Widget _buildEditorField({
    required Key key,
    required String initialValue,
    required String hintText,
    required ValueChanged<String> onChanged,
    FontWeight fontWeight = FontWeight.normal,
    double minHeight = 43,
    int? maxLines = 1,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextFormField(
        key: key,
        initialValue: initialValue,
        onChanged: onChanged,
        maxLines: maxLines,
        textAlignVertical: maxLines == 1
            ? TextAlignVertical.center
            : TextAlignVertical.top,
        style: TextStyle(
          color: GacColors.black,
          fontSize: 10,
          height: maxLines == 1 ? null : 1.5,
          fontWeight: fontWeight,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: GacColors.muted, fontSize: 10),
          filled: true,
          fillColor: GacColors.offWhite,
          isDense: true,
          contentPadding: const EdgeInsets.all(11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(maxLines == 1 ? 11 : 12),
            borderSide: const BorderSide(color: GacColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(maxLines == 1 ? 11 : 12),
            borderSide: const BorderSide(color: GacColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow(String sectionId, ChecklistItem item) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final level in _levels)
          Semantics(
            button: true,
            selected: item.level == level,
            label: '$level checklist level',
            excludeSemantics: true,
            child: Material(
              color: item.level == level ? GacColors.primary : GacColors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: item.level == level
                      ? GacColors.primary
                      : GacColors.border,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _updateItem(
                  sectionId,
                  item.id,
                  (current) => current.copyWith(level: level),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: item.level == level
                          ? GacColors.white
                          : GacColors.gray,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAuditItem(String sectionId, ChecklistItem item) {
    final hasSubject = item.subject?.isNotEmpty == true;
    final hasMeta = item.level != null || hasSubject;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasMeta) ...[
          Row(
            children: [
              if (item.level != null) ...[
                AdminStatusPill(
                  label: item.level!,
                  tone: item.level == 'Basic'
                      ? AdminStatusTone.dark
                      : AdminStatusTone.neutral,
                ),
                if (hasSubject) const SizedBox(width: 8),
              ],
              if (hasSubject)
                Expanded(
                  child: Text(
                    item.subject!.toUpperCase(),
                    style: const TextStyle(
                      color: GacColors.gray,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
        ],
        Text(
          item.text,
          style: const TextStyle(
            color: GacColors.black,
            fontSize: 10,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < _responses.length; index++) ...[
              Expanded(
                child: _buildResponseButton(sectionId, item, _responses[index]),
              ),
              if (index < _responses.length - 1) const SizedBox(width: 7),
            ],
          ],
        ),
        if (item.response == 'NO' || item.response == 'N/A') ...[
          const SizedBox(height: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 75),
            child: TextFormField(
              key: ValueKey('remark-${item.id}-$_remarksRevision'),
              initialValue: _remarks[item.id] ?? '',
              onChanged: (value) => _remarks[item.id] = value,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: GacColors.black,
                fontSize: 10,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Remarks, reason, or corrective action...',
                hintStyle: const TextStyle(
                  color: GacColors.muted,
                  fontSize: 10,
                ),
                filled: true,
                fillColor: GacColors.offWhite,
                isDense: true,
                contentPadding: const EdgeInsets.all(11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: GacColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: GacColors.primary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResponseButton(
    String sectionId,
    ChecklistItem item,
    String response,
  ) {
    final selected = item.response == response;
    final selectedColor = switch (response) {
      'YES' => GacColors.success,
      'NO' => GacColors.error,
      _ => GacColors.warning,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$response response',
      excludeSemantics: true,
      child: Material(
        color: selected ? selectedColor : GacColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: selected ? selectedColor : GacColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _updateItem(
            sectionId,
            item.id,
            (current) => selected
                ? current.copyWith(clearResponse: true)
                : current.copyWith(response: response),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 37),
            child: Center(
              child: Text(
                response,
                style: TextStyle(
                  color: selected ? GacColors.white : GacColors.gray,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemButton(String sectionId) {
    return Material(
      color: GacColors.offWhite,
      child: InkWell(
        onTap: () => _addItem(sectionId),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: GacColors.lightGray)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 18, color: GacColors.primary),
              SizedBox(width: 7),
              Text(
                'ADD ITEM TO THIS SECTION',
                style: TextStyle(
                  color: GacColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return AdminSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 17),
      child: const Column(
        children: [
          Icon(Icons.search_outlined, size: 27, color: GacColors.gray),
          SizedBox(height: 10),
          Text(
            'No matching checklist items',
            style: TextStyle(
              color: GacColors.black,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different search term.',
            style: TextStyle(color: GacColors.gray, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildEditFooter() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        AdminActionButton(
          label: 'Add Coverage Area',
          icon: Icons.add_circle_outline,
          onPressed: _addSection,
        ),
        AdminActionButton(
          label: 'Restore Original',
          icon: Icons.refresh_outlined,
          variant: AdminActionButtonVariant.danger,
          onPressed: () => unawaited(_restorePreset()),
        ),
        AdminActionButton(
          label: 'Save Master Preset',
          icon: Icons.save_outlined,
          variant: AdminActionButtonVariant.primary,
          onPressed: () => unawaited(_savePreset()),
        ),
      ],
    );
  }

  Widget _buildAuditFooter() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: [
        AdminActionButton(
          label: 'Reset Responses',
          icon: Icons.refresh_outlined,
          onPressed: _resetResponses,
        ),
        AdminActionButton(
          label: 'Save Draft',
          icon: Icons.save_outlined,
          onPressed: () => unawaited(
            _showMessage(
              title: 'Draft saved',
              message: 'The displayed responses were saved locally.',
            ),
          ),
        ),
        AdminActionButton(
          label: _isDos ? 'Submit Audit' : 'Submit Checklist',
          icon: Icons.check_circle_outline,
          variant: AdminActionButtonVariant.primary,
          onPressed: () => unawaited(_submitAudit()),
        ),
      ],
    );
  }
}
