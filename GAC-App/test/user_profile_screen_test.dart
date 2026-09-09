import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/models/user_notification.dart';
import 'package:gac_flutter/screens/user_profile_screen.dart';
import 'package:gac_flutter/services/notification_service.dart';
import 'package:gac_flutter/services/profile_service.dart';
import 'package:gac_flutter/theme/gac_theme.dart';
import 'package:gac_flutter/widgets/user_avatar.dart';
import 'package:gac_flutter/widgets/user_tabs_layout.dart';

const _profile = AuthenticatedUser(
  id: 8,
  name: 'Jamie Cruz',
  email: 'jamie@gateway.local',
  branch: 'Makati',
  userType: 'PIC',
  picAssignmentType: 'utilities',
  picAssignmentLabel: 'Utilities',
  accountStatus: 'active',
);

void main() {
  testWidgets('authenticated profile identity reaches the floating header', (
    tester,
  ) async {
    final notifications = UserNotificationController(
      repository: _EmptyNotificationRepository(),
    );
    await notifications.load();
    addTearDown(notifications.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserTabsLayout(
          profileRepository: _ProfileRepository(_profile),
          notificationController: notifications,
        ),
      ),
    );
    await tester.pump();

    final avatar = tester.widget<UserAvatar>(
      find.byKey(const ValueKey('user-home-profile-icon')),
    );
    expect(avatar.user.name, 'Jamie Cruz');
    expect(avatar.user.initials, 'JC');
  });

  testWidgets('edits authenticated profile information from the profile UI', (
    tester,
  ) async {
    final repository = _ProfileRepository(_profile);
    AuthenticatedUser? updated;
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserProfileScreen(
          initialProfile: _profile,
          repository: repository,
          onProfileUpdated: (profile) => updated = profile,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Jamie Cruz'), findsOneWidget);
    expect(find.text('Utilities'), findsWidgets);
    expect(find.text('Makati'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-profile-information')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      'Jamie Updated',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-email-field')),
      'updated@gateway.local',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile-information')));
    await tester.pumpAndSettle();

    expect(find.text('Jamie Updated'), findsOneWidget);
    expect(updated?.name, 'Jamie Updated');
    expect(repository.updatedEmail, 'updated@gateway.local');
  });

  testWidgets('validates and submits a password change', (tester) async {
    final repository = _ProfileRepository(_profile);
    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserProfileScreen(
          initialProfile: _profile,
          repository: repository,
        ),
      ),
    );
    await tester.pump();
    await tester.drag(
      find.byKey(const PageStorageKey<String>('user-profile-scroll')),
      const Offset(0, -520),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('change-password-action')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('current-password-field')),
      'current-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'new-secret-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'different',
    );
    await tester.tap(find.byKey(const ValueKey('save-new-password')));
    await tester.pump();
    expect(find.text('The passwords do not match.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'new-secret-123',
    );
    await tester.tap(find.byKey(const ValueKey('save-new-password')));
    await tester.pumpAndSettle();

    expect(repository.changedPassword, 'new-secret-123');
    expect(find.text('Password updated successfully.'), findsOneWidget);
  });

  testWidgets('removes redundant role in parenthesis from user name on profile', (
    tester,
  ) async {
    const roleProfile = AuthenticatedUser(
      id: 9,
      name: 'Marcus Sales (Sales Manager)',
      email: 'marcus@gateway.local',
      branch: 'Makati',
      userType: 'SALES_MANAGER',
      accountStatus: 'active',
    );
    final repository = _ProfileRepository(roleProfile);

    await tester.pumpWidget(
      MaterialApp(
        theme: GacTheme.light,
        home: UserProfileScreen(
          initialProfile: roleProfile,
          repository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Marcus Sales'), findsOneWidget);
    expect(find.text('Marcus Sales (Sales Manager)'), findsNothing);
    expect(find.text('SALES MANAGER'), findsOneWidget);
    expect(roleProfile.initials, 'MS');
  });
}

class _ProfileRepository implements ProfileRepository {
  _ProfileRepository(this.profile);

  AuthenticatedUser profile;
  String? updatedEmail;
  String? changedPassword;

  @override
  Future<AuthenticatedUser?> loadCachedProfile() async => profile;

  @override
  Future<AuthenticatedUser> fetchProfile() async => profile;

  @override
  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  }) async {
    updatedEmail = email;
    profile = AuthenticatedUser(
      id: profile.id,
      name: name,
      email: email,
      branch: profile.branch,
      userType: profile.userType,
      picAssignmentType: profile.picAssignmentType,
      picAssignmentLabel: profile.picAssignmentLabel,
      accountStatus: profile.accountStatus,
      avatarUrl: profile.avatarUrl,
    );
    return profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    expect(currentPassword, 'current-secret');
    expect(passwordConfirmation, password);
    changedPassword = password;
  }

  @override
  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async => profile;

  @override
  Future<AuthenticatedUser> deleteAvatar() async => profile;

  @override
  Future<void> logout() async {}
}

class _EmptyNotificationRepository implements NotificationRepository {
  @override
  Future<NotificationInbox> fetchNotifications() async =>
      const NotificationInbox(notifications: [], unreadCount: 0);

  @override
  Future<NotificationInbox> markRead(String id) async =>
      const NotificationInbox(notifications: [], unreadCount: 0);

  @override
  Future<int> markAllRead() async => 0;
}
