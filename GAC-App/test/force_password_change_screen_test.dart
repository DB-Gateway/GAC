import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/models/authenticated_user.dart';
import 'package:gac_flutter/screens/force_password_change_screen.dart';
import 'package:gac_flutter/services/profile_service.dart';

class _MockProfileRepository implements ProfileRepository {
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastConfirmation;
  bool logoutCalled = false;

  @override
  Future<AuthenticatedUser?> loadCachedProfile() async {
    return const AuthenticatedUser(
      id: 10,
      name: 'New Employee',
      email: 'employee@gateway.local',
      userType: 'PIC',
      accountStatus: 'active',
      mustChangePassword: true,
    );
  }

  @override
  Future<AuthenticatedUser> fetchProfile() async {
    return (await loadCachedProfile())!;
  }

  @override
  Future<AuthenticatedUser> updateProfile({
    required String name,
    required String email,
  }) async {
    return (await loadCachedProfile())!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    lastCurrentPassword = currentPassword;
    lastNewPassword = password;
    lastConfirmation = passwordConfirmation;
  }

  @override
  Future<AuthenticatedUser> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    return (await loadCachedProfile())!;
  }

  @override
  Future<AuthenticatedUser> deleteAvatar() async {
    return (await loadCachedProfile())!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  testWidgets('renders force password change screen with pre-filled default password', (
    tester,
  ) async {
    final mockRepo = _MockProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: ForcePasswordChangeScreen(
          currentPassword: 'Gateway@2026',
          destination: '/(user)/home',
          profileRepository: mockRepo,
        ),
      ),
    );

    expect(find.text('Password Change Required'), findsOneWidget);
    expect(find.text('CURRENT TEMPORARY PASSWORD'), findsOneWidget);
    expect(find.text('NEW PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM NEW PASSWORD'), findsOneWidget);
    expect(find.text('Update Password & Continue'), findsOneWidget);
    expect(find.text('Sign Out Instead'), findsOneWidget);
  });

  testWidgets('validates password length and match before submitting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _MockProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/(user)/home': (_) => const Scaffold(body: Text('User Home Screen')),
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
        },
        home: ForcePasswordChangeScreen(
          currentPassword: 'Gateway@2026',
          destination: '/(user)/home',
          profileRepository: mockRepo,
        ),
      ),
    );

    // Try submitting empty
    await tester.tap(find.text('Update Password & Continue'));
    await tester.pump();

    expect(find.text('Enter your new password.'), findsOneWidget);

    // Try short password
    final newPassField = find.widgetWithText(TextFormField, 'At least 8 characters');
    final confirmPassField = find.widgetWithText(TextFormField, 'Re-type your new password');

    await tester.enterText(newPassField, 'short');
    await tester.enterText(confirmPassField, 'short');
    await tester.tap(find.text('Update Password & Continue'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters.'), findsOneWidget);

    // Try same password as current
    await tester.enterText(newPassField, 'Gateway@2026');
    await tester.enterText(confirmPassField, 'Gateway@2026');
    await tester.tap(find.text('Update Password & Continue'));
    await tester.pump();

    expect(
      find.text('New password must be different from current password.'),
      findsOneWidget,
    );

    // Try mismatched passwords
    await tester.enterText(newPassField, 'BrandNewPass123!');
    await tester.enterText(confirmPassField, 'DifferentPass123!');
    await tester.tap(find.text('Update Password & Continue'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);

    // Valid submission
    await tester.enterText(confirmPassField, 'BrandNewPass123!');
    await tester.tap(find.text('Update Password & Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(mockRepo.lastCurrentPassword, 'Gateway@2026');
    expect(mockRepo.lastNewPassword, 'BrandNewPass123!');
    expect(mockRepo.lastConfirmation, 'BrandNewPass123!');
  });
}
