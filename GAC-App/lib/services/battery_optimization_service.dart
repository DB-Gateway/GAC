import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Manages battery-optimization exemption on Android so that scheduled
/// notifications and background work are not killed by Doze mode.
class BatteryOptimizationService {
  BatteryOptimizationService._();

  static final BatteryOptimizationService instance =
      BatteryOptimizationService._();

  static const _channel = MethodChannel('com.gateway.gac_flutter/battery');

  /// Whether the platform is Android (the only OS where this matters).
  bool get _isAndroid =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Returns `true` when the app is already exempt from battery optimizations.
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!_isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Shows the system dialog that asks the user to disable battery
  /// optimization for this app.  Does nothing if already exempt.
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } on PlatformException {
      // Silently ignore — older devices may not support this intent.
    }
  }

  /// Opens the full battery-optimization settings list.
  Future<void> openBatteryOptimizationSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } on PlatformException {
      // Silently ignore.
    }
  }

  /// Opens the device manufacturer's Auto-Start / Background App Management settings
  /// (especially critical on Xiaomi, Oppo, Vivo, Huawei, and Samsung).
  Future<bool> openAutoStartSettings() async {
    if (!_isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openAutoStartSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Returns the device manufacturer in lowercase (e.g. "samsung", "xiaomi").
  Future<String?> getManufacturer() async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getManufacturer');
    } on PlatformException {
      return null;
    }
  }

  /// Convenience: check and prompt in one call.  Returns `true` when
  /// the app is already exempt (so no dialog was shown).
  Future<bool> ensureExempt() async {
    if (!_isAndroid) return true;
    final alreadyExempt = await isIgnoringBatteryOptimizations();
    if (!alreadyExempt) {
      await requestIgnoreBatteryOptimizations();
    }
    return alreadyExempt;
  }
}
