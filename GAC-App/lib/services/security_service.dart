import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  String _pinKey(String? email) {
    if (email != null && email.trim().isNotEmpty) {
      return '${gacSecurityPinKey}_${email.trim().toLowerCase()}';
    }
    return gacSecurityPinKey;
  }

  Future<bool> hasPin({String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (email != null && email.trim().isNotEmpty) {
        final userPin = prefs.getString(_pinKey(email));
        return userPin != null && userPin.trim().length == 4;
      }
      final pin = prefs.getString(gacSecurityPinKey);
      return pin != null && pin.trim().length == 4;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getStoredPin({String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (email != null && email.trim().isNotEmpty) {
        final userPin = prefs.getString(_pinKey(email));
        if (userPin != null && userPin.trim().length == 4) return userPin;
        return null;
      }
      return prefs.getString(gacSecurityPinKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> verifyPin(String pin, {String? email}) async {
    try {
      final stored = await getStoredPin(email: email);
      return stored != null && stored.trim() == pin.trim();
    } catch (_) {
      return false;
    }
  }

  Future<bool> savePin(String pin, {String? email}) async {
    if (pin.trim().length != 4) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = pin.trim();
      if (email != null && email.trim().isNotEmpty) {
        await prefs.setString(_pinKey(email), trimmed);
      }
      return await prefs.setString(gacSecurityPinKey, trimmed);
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePin({String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (email != null && email.trim().isNotEmpty) {
        await prefs.remove(_pinKey(email));
      }
      await prefs.remove(gacSecurityPinKey);
      await prefs.remove(gacBiometricsEnabledKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricsSupported() async {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return false;
    }
    try {
      final canCheck = await _localAuth.canCheckBiometrics.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      final isSupported = await _localAuth.isDeviceSupported().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('isBiometricsSupported error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return const [];
    try {
      return await _localAuth.getAvailableBiometrics().timeout(
        const Duration(seconds: 2),
        onTimeout: () => const [],
      );
    } catch (e) {
      debugPrint('getAvailableBiometrics error: $e');
      return const [];
    }
  }

  Future<bool> hasEnrolledBiometrics() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getBool(gacBiometricsEnabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(gacBiometricsEnabledKey, enabled);
    } catch (_) {
      // Ignored
    }
  }

  Future<BiometricAuthResult> authenticateWithBiometricsDetailed({
    String reason = 'Scan your fingerprint to unlock Gateway Audit Compliance',
  }) async {
    if (kIsWeb) {
      return const BiometricAuthResult(
        success: false,
        status: BiometricAuthStatus.notSupported,
        message: 'Biometrics are not supported on web.',
      );
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return const BiometricAuthResult(
        success: false,
        status: BiometricAuthStatus.notSupported,
        message: 'Biometrics not available in test environment.',
      );
    }

    try {
      final supported = await isBiometricsSupported();
      if (!supported) {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.notSupported,
          message: 'Fingerprint scanner is not supported on this device.',
        );
      }

      final enrolled = await getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.notEnrolled,
          message: 'No fingerprint enrolled. Please set up a fingerprint in Android Settings first.',
        );
      }

      final authenticated = await _localAuth
          .authenticate(
            localizedReason: reason,
            biometricOnly: true,
            persistAcrossBackgrounding: true,
          )
          .timeout(const Duration(seconds: 25), onTimeout: () => false);

      if (authenticated) {
        return const BiometricAuthResult(
          success: true,
          status: BiometricAuthStatus.success,
          message: 'Fingerprint verified successfully.',
        );
      } else {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.cancelled,
          message: 'Fingerprint authentication cancelled.',
        );
      }
    } on LocalAuthException catch (e) {
      debugPrint('LocalAuthException: ${e.code} - ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          return const BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.notEnrolled,
            message: 'No fingerprint enrolled. Please set up a fingerprint in Android Settings first.',
          );
        case LocalAuthExceptionCode.noCredentialsSet:
          return const BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.passcodeNotSet,
            message: 'No device screen lock set. Please configure a PIN or password in Android Settings first.',
          );
        case LocalAuthExceptionCode.noBiometricHardware:
          return const BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.notSupported,
            message: 'Fingerprint scanner is not supported on this device.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.lockedOut,
            message: 'Biometrics temporarily locked. Please try again later.',
          );
        case LocalAuthExceptionCode.userCanceled:
          return const BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.cancelled,
            message: 'Fingerprint authentication cancelled.',
          );
        default:
          return BiometricAuthResult(
            success: false,
            status: BiometricAuthStatus.error,
            message: e.description ?? 'Biometric authentication error.',
          );
      }
    } on PlatformException catch (e) {
      debugPrint(
        'Biometric authentication PlatformException: ${e.code} - ${e.message}',
      );
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.notEnrolled,
          message: 'No fingerprint enrolled. Please set up a fingerprint in Android Settings first.',
        );
      } else if (e.code == 'PasscodeNotSet') {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.passcodeNotSet,
          message: 'No device screen lock set. Please configure a PIN or password in Android Settings first.',
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          success: false,
          status: BiometricAuthStatus.lockedOut,
          message: 'Biometrics temporarily locked. Please try again later.',
        );
      }
      return BiometricAuthResult(
        success: false,
        status: BiometricAuthStatus.error,
        message: e.message ?? 'Biometric authentication failed.',
      );
    } catch (e) {
      debugPrint('Biometric authentication unexpected error: $e');
      return const BiometricAuthResult(
        success: false,
        status: BiometricAuthStatus.error,
        message: 'Fingerprint authentication encountered an error.',
      );
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Scan your fingerprint to unlock Gateway Audit Compliance',
  }) async {
    final result = await authenticateWithBiometricsDetailed(reason: reason);
    return result.success;
  }
}

enum BiometricAuthStatus {
  success,
  cancelled,
  notSupported,
  notEnrolled,
  passcodeNotSet,
  lockedOut,
  error,
}

class BiometricAuthResult {
  final bool success;
  final BiometricAuthStatus status;
  final String message;

  const BiometricAuthResult({
    required this.success,
    required this.status,
    required this.message,
  });
}
