import 'package:flutter_test/flutter_test.dart';
import 'package:gac_flutter/services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecurityService PIN operations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasPin returns false when no PIN is set', () async {
      expect(await SecurityService.instance.hasPin(), isFalse);
    });

    test('savePin stores 4-digit PIN and verifyPin validates correctly', () async {
      final saved = await SecurityService.instance.savePin('1234');
      expect(saved, isTrue);
      expect(await SecurityService.instance.hasPin(), isTrue);
      expect(await SecurityService.instance.verifyPin('1234'), isTrue);
      expect(await SecurityService.instance.verifyPin('0000'), isFalse);
      expect(await SecurityService.instance.verifyPin('123'), isFalse);
    });

    test('savePin rejects non-4-digit PINs', () async {
      expect(await SecurityService.instance.savePin('12'), isFalse);
      expect(await SecurityService.instance.savePin('12345'), isFalse);
      expect(await SecurityService.instance.hasPin(), isFalse);
    });

    test('removePin clears PIN and biometrics preference', () async {
      await SecurityService.instance.savePin('4321');
      await SecurityService.instance.setBiometricsEnabled(true);
      expect(await SecurityService.instance.hasPin(), isTrue);
      expect(await SecurityService.instance.isBiometricsEnabled(), isTrue);

      await SecurityService.instance.removePin();
      expect(await SecurityService.instance.hasPin(), isFalse);
      expect(await SecurityService.instance.isBiometricsEnabled(), isFalse);
    });

    test('biometric methods return safe fallback in test environment', () async {
      expect(await SecurityService.instance.isBiometricsSupported(), isFalse);
      final result = await SecurityService.instance.authenticateWithBiometricsDetailed();
      expect(result.success, isFalse);
      expect(result.status, BiometricAuthStatus.notSupported);
      expect(await SecurityService.instance.authenticateWithBiometrics(), isFalse);
    });
  });
}
