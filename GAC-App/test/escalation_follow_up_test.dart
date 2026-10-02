import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/config/api_config.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/escalation_follow_up.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/services/escalation_follow_up_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/escalation_details_dialog.dart';
import 'package:gac_flutter/widgets/escalation_follow_up_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notice = UserNotification(
  id: 'escalation-1',
  type: 'finding_escalated',
  title: 'Escalation',
  message: 'Review the finding',
  unread: true,
  data: {
    'question': 'Is the signage in good condition?',
    'sender_name': 'Brenda BOM',
  },
);

void main() {
  testWidgets('follow-up requires a remark and Others requires nonblank text', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository);
    await tester.tap(find.text('Send follow-up'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a remark to continue.'), findsOneWidget);
    expect(repository.calls, 0);

    await _choose(tester, 'Others');
    await tester.tap(find.text('Send follow-up'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your follow-up remarks.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Send follow-up'));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);

    await tester.enterText(
      find.byType(TextFormField),
      '  Contractor will inspect tomorrow.  ',
    );
    await tester.tap(find.text('Send follow-up'));
    await tester.pumpAndSettle();
    expect(repository.otherRemarks, 'Contractor will inspect tomorrow.');
    expect(repository.photos, isEmpty);
    expect(find.text('Follow-up sent to Brenda BOM.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('escalation-follow-up-sheet')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preset submission discards custom text and prevents duplicate taps',
    (tester) async {
      final repository = _Repository()
        ..pending = Completer<EscalationFollowUp>();
      await _open(tester, repository);
      await _choose(tester, 'Others');
      await tester.enterText(
        find.byType(TextFormField),
        'An old custom remark',
      );
      await _choose(tester, 'Corrective action in progress');
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.text('Send follow-up'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-escalation-follow-up')));
      await tester.pump();
      expect(repository.calls, 1);
      expect(repository.otherRemarks, isEmpty);
      expect(repository.remark, EscalationRemark.inProgress);
      repository.pending!.complete(_receipt);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'camera photos can be removed and network retries retain the form',
    (tester) async {
      final repository = _Repository()..fail = true;
      final picker = _Camera();
      await _open(tester, repository, picker: picker);
      await _choose(tester, 'Corrective action in progress');
      final camera = find.byKey(const ValueKey('follow-up-take-photo'));
      await tester.ensureVisible(camera);
      await tester.tap(camera);
      await tester.pumpAndSettle();
      expect(picker.sources, [ImageSource.camera]);
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove photo 1'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo 1'), findsNothing);
      await tester.ensureVisible(camera);
      await tester.tap(camera);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send follow-up'));
      await tester.pumpAndSettle();
      expect(find.text('Connection unavailable. Try again.'), findsOneWidget);
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      final requestId = repository.requestIds.single;
      repository.fail = false;
      await tester.tap(find.text('Send follow-up'));
      await tester.pumpAndSettle();
      expect(repository.requestIds, [requestId, requestId]);
      expect(repository.photos.single.filename, 'camera.png');
      expect(picker.sources, everyElement(ImageSource.camera));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'camera cancellation stays optional and keyboard does not overflow',
    (tester) async {
      final repository = _Repository();
      await _open(tester, repository, picker: _Camera()..cancel = true);
      await _choose(tester, 'Others');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(
        find.byType(TextFormField),
        'Waiting for supplier confirmation.',
      );
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      final camera = find.byKey(const ValueKey('follow-up-take-photo'));
      await tester.ensureVisible(camera);
      await tester.tap(camera);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remove photo 1'), findsNothing);
      await tester.tap(find.text('Send follow-up'));
      await tester.pumpAndSettle();
      expect(repository.photos, isEmpty);
    },
  );

  testWidgets(
    'shows selected dropdown text and does not clip or hide it',
    (tester) async {
      final repository = _Repository();
      await _open(tester, repository);

      expect(find.text('Select a remark'), findsOneWidget);

      await _choose(tester, 'Awaiting approval or budget');

      final selectedFinder = find.text('Awaiting approval or budget');
      expect(selectedFinder, findsOneWidget);

      final textRenderObject = tester.renderObject(selectedFinder);
      expect(textRenderObject.paintBounds.height, greaterThanOrEqualTo(14.0));
    },
  );

  testWidgets(
    'displays checklist answer, finding, and attachment preview with full viewer',
    (tester) async {
      const richNotice = UserNotification(
        id: 'escalation-2',
        type: 'finding_escalated',
        title: 'Escalation with Finding',
        message: 'Review the finding',
        unread: true,
        data: {
          'question': 'Are fire exits unobstructed?',
          'status': 'no',
          'finding': 'Boxes blocking exit door in storage bay',
          'attachment_url': 'checklist-attachments/fire-exit.jpg',
          'sender_name': 'Brenda BOM',
        },
      );

      final repository = _Repository();
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Scaffold(
            body: EscalationFollowUpSheet(
              notification: richNotice,
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Are fire exits unobstructed?'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
      expect(
        find.text('Boxes blocking exit door in storage bay'),
        findsOneWidget,
      );
      expect(find.text('Attachment'), findsOneWidget);
      expect(find.text('Tap to enlarge'), findsOneWidget);

      await tester.tap(find.text('Tap to enlarge'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close image'), findsOneWidget);

      await tester.tap(find.byTooltip('Close image'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close image'), findsNothing);
    },
  );

  testWidgets(
    'already followed up escalation hides follow-up button and shows completed banner',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const doneNotice = UserNotification(
        id: 'escalation-done',
        type: 'finding_escalated',
        title: 'Escalation',
        message: 'Review the finding',
        unread: false,
        data: {
          'question': 'Is the signage in good condition?',
          'sender_name': 'Brenda BOM',
          'has_follow_up': true,
          'follow_up_recipient_name': 'Brenda BOM',
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEscalationDetailsDialog(
                  context,
                  doneNotice,
                ),
                child: const Text('Open escalation'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open escalation'));
      await tester.pumpAndSettle();

      // Follow-up button should NOT exist!
      expect(find.byKey(const ValueKey('escalation-follow-up')), findsNothing);
      expect(find.text('Follow-up'), findsNothing);

      // Completed banner should be shown!
      expect(
        find.byKey(const ValueKey('escalation-follow-up-done-banner')),
        findsOneWidget,
      );
      expect(find.text('Follow-up already sent to Brenda BOM.'), findsOneWidget);

      // Close button should be shown and can be tapped
      expect(
        find.byKey(const ValueKey('escalation-details-close')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('escalation-details-close')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('escalation-details-dialog')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'non-utility user sees notice banner and cannot follow up on escalation',
    (tester) async {
      const salesUser = AuthenticatedUser(
        id: 10,
        name: 'Sam Sales',
        email: 'sam@gac.ph',
        userType: 'SALES_MANAGER',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEscalationDetailsDialog(
                  context,
                  _notice,
                  currentUser: salesUser,
                  canFollowUp: false,
                ),
                child: const Text('Open escalation'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open escalation'));
      await tester.pumpAndSettle();

      // Follow-up button should NOT exist
      expect(find.byKey(const ValueKey('escalation-follow-up')), findsNothing);
      expect(find.text('Follow-up'), findsNothing);

      // Utility-only banner should be visible
      expect(
        find.byKey(const ValueKey('escalation-utility-only-banner')),
        findsOneWidget,
      );
      expect(
        find.text('Only utility personnel can submit a follow-up for this escalation.'),
        findsOneWidget,
      );

      // Close button should be present and work
      expect(
        find.byKey(const ValueKey('escalation-details-close')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('escalation-details-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('escalation-details-dialog')), findsNothing);
    },
  );

  testWidgets(
    'utility user sees follow-up button on escalation and can open sheet',
    (tester) async {
      const utilityUser = AuthenticatedUser(
        id: 12,
        name: 'Ursula Utility',
        email: 'ursula@gac.ph',
        userType: '5S_UTILITIES',
        accountStatus: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GacTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showEscalationDetailsDialog(
                  context,
                  _notice,
                  currentUser: utilityUser,
                  canFollowUp: true,
                ),
                child: const Text('Open escalation'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open escalation'));
      await tester.pumpAndSettle();

      // Follow-up button should exist
      expect(find.byKey(const ValueKey('escalation-follow-up')), findsOneWidget);
      expect(find.text('Follow-up'), findsOneWidget);

      // Utility-only banner should NOT be visible
      expect(
        find.byKey(const ValueKey('escalation-utility-only-banner')),
        findsNothing,
      );
    },
  );

  test(
    'EscalationFollowUpApiService rejects non-utility users',
    () async {
      SharedPreferences.setMockInitialValues({
        gacAuthTokenKey: 'test-token',
        gacPreviousUserIdKey: '10',
        gacAuthUserKey: jsonEncode(const AuthenticatedUser(
          id: 10,
          name: 'Sam Sales',
          email: 'sam@gac.ph',
          userType: 'SALES_MANAGER',
          accountStatus: 'active',
        ).toJson()),
      });

      final service = EscalationFollowUpApiService();
      const notif = UserNotification(
        id: 'notif-1',
        type: 'finding_escalated',
        title: 'Escalated',
        message: 'Review finding',
        unread: false,
        data: {'recipient_user_id': 10},
      );

      expect(
        () => service.submit(
          notification: notif,
          requestId: '0123456789abcdef0123456789abcdef',
          remark: EscalationRemark.inProgress,
          otherRemarks: '',
          photos: [],
        ),
        throwsA(
          isA<EscalationFollowUpException>().having(
            (e) => e.message,
            'message',
            'Only utility personnel can submit an escalation follow-up.',
          ),
        ),
      );
    },
  );
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  ImagePicker? picker,
}) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: GacTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => EscalationDetailsDialog(
                notification: _notice,
                followUpRepository: repository,
                imagePicker: picker,
              ),
            ),
            child: const Text('Open escalation'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open escalation'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Follow-up'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label) async {
  final dropdown = find.byType(DropdownButtonFormField<EscalationRemark>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(label).hitTestable(),
    label == 'Others' ? 150 : -150,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text(label).hitTestable());
  await tester.pumpAndSettle();
}

final _receipt = EscalationFollowUp(
  id: 1,
  remarks: 'Update',
  recipientName: 'Brenda BOM',
  createdAt: DateTime.utc(2026, 9, 14),
);

class _Repository implements EscalationFollowUpRepository {
  int calls = 0;
  bool fail = false;
  Completer<EscalationFollowUp>? pending;
  String? otherRemarks;
  EscalationRemark? remark;
  List<FollowUpPhoto> photos = [];
  List<String> requestIds = [];

  @override
  Future<EscalationFollowUp> submit({
    required UserNotification notification,
    required String requestId,
    required EscalationRemark remark,
    required String otherRemarks,
    required List<FollowUpPhoto> photos,
  }) async {
    calls++;
    requestIds.add(requestId);
    this.remark = remark;
    this.otherRemarks = otherRemarks;
    this.photos = photos;
    if (fail) {
      throw const EscalationFollowUpException(
        'Connection unavailable. Try again.',
      );
    }
    return pending?.future ?? Future.value(_receipt);
  }
}

class _Camera extends ImagePicker {
  bool cancel = false;
  final sources = <ImageSource>[];

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    sources.add(source);
    if (cancel) return null;
    return XFile.fromData(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aDa8AAAAASUVORK5CYII=',
      ),
      name: 'camera.png',
      path: 'camera.png',
      mimeType: 'image/png',
    );
  }
}
