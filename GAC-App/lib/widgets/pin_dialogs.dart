import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/security_service.dart';
import '../theme/gac_theme.dart';

/// Animated PIN indicator dots (6 digits default)
class PinDots extends StatelessWidget {
  const PinDots({
    required this.length,
    this.total = 6,
    this.hasError = false,
    super.key,
  });

  final int length;
  final int total;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isFilled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          // Overshooting curves can make an outgoing BoxShadow's interpolated
          // blur radius negative, which is rejected by dart:ui while painting.
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? GacColors.brandRed
                : isFilled
                ? GacColors.cyan
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? GacColors.brandRed
                  : isFilled
                  ? GacColors.cyan
                  : const Color(0xFF475569),
              width: 2,
            ),
            boxShadow: isFilled && !hasError
                ? const [
                    BoxShadow(
                      color: Color(0x6600BCD4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// A customized on-screen numeric keypad for 4-digit PIN entry
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.showBiometric = false,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool showBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 14),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 14),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left bottom action: Biometrics or empty
            SizedBox(
              width: 68,
              height: 68,
              child: showBiometric && onBiometric != null
                  ? Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onBiometric!();
                        },
                        customBorder: const CircleBorder(),
                        child: const Center(
                          child: Icon(
                            Icons.fingerprint_rounded,
                            size: 32,
                            color: GacColors.cyan,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 24),
            _buildKey(context, '0'),
            const SizedBox(width: 24),
            // Right bottom action: Backspace
            SizedBox(
              width: 68,
              height: 68,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onBackspace();
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 24,
                      color: GacColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          _buildKey(context, digits[i]),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onDigit(digit);
          },
          customBorder: const CircleBorder(),
          highlightColor: const Color(0x3300BCD4),
          splashColor: const Color(0x4400BCD4),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                color: GacColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog / Sheet to create, confirm, or change a 4-digit PIN
Future<bool> showPinSetupDialog(
  BuildContext context, {
  bool isChanging = false,
  String? email,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) =>
        _PinSetupSheet(isChanging: isChanging, email: email),
  );
  return result ?? false;
}

class _PinSetupSheet extends StatefulWidget {
  const _PinSetupSheet({required this.isChanging, this.email});

  final bool isChanging;
  final String? email;

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  // Steps:
  // 0: enter current PIN (only if isChanging)
  // 1: enter new PIN
  // 2: confirm new PIN
  // 3: success / biometrics option
  late int _step;
  int _expectedCurrentPinLength = 6;
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;
  bool _biometricsSupported = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _step = widget.isChanging ? 0 : 1;
    _checkBiometrics();
    _checkCurrentPinLength();
  }

  Future<void> _checkCurrentPinLength() async {
    final stored = await SecurityService.instance.getStoredPin(
      email: widget.email,
    );
    if (mounted && stored != null && stored.trim().isNotEmpty) {
      setState(() {
        _expectedCurrentPinLength = stored.trim().length;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    final supported = await SecurityService.instance.isBiometricsSupported();
    final enabled = await SecurityService.instance.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _biometricsSupported = supported;
        _biometricsEnabled = enabled;
      });
    }
  }

  String get _activePin {
    switch (_step) {
      case 0:
        return _currentPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _onDigit(String digit) {
    final maxLen = _step == 0 ? _expectedCurrentPinLength : 6;
    if (_activePin.length >= maxLen) return;
    setState(() {
      _errorMessage = null;
      if (_step == 0) {
        _currentPin += digit;
        if (_currentPin.length == _expectedCurrentPinLength) {
          _handleCurrentPinEntered();
        }
      } else if (_step == 1) {
        _newPin += digit;
        if (_newPin.length == 6) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) setState(() => _step = 2);
          });
        }
      } else if (_step == 2) {
        _confirmPin += digit;
        if (_confirmPin.length == 6) _handleConfirmPinEntered();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (_step == 0 && _currentPin.isNotEmpty) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      } else if (_step == 1 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 2 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future<void> _handleCurrentPinEntered() async {
    final valid = await SecurityService.instance.verifyPin(
      _currentPin,
      email: widget.email,
    );
    if (!mounted) return;
    if (valid) {
      setState(() {
        _step = 1;
        _errorMessage = null;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Current PIN is incorrect. Try again.';
        _currentPin = '';
      });
    }
  }

  Future<void> _handleConfirmPinEntered() async {
    if (_confirmPin != _newPin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Please re-enter.';
        _confirmPin = '';
      });
      return;
    }

    // PIN confirmed! Save PIN
    await SecurityService.instance.savePin(_newPin, email: widget.email);

    if (_biometricsSupported) {
      // Show biometrics preference step
      if (mounted) {
        setState(() => _step = 3);
      }
    } else {
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _finishSetup() async {
    if (_biometricsSupported) {
      await SecurityService.instance.setBiometricsEnabled(_biometricsEnabled);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      0 => 'Enter Current PIN',
      1 => widget.isChanging ? 'Create New 6-Digit PIN' : 'Create 6-Digit PIN',
      2 => 'Confirm 6-Digit PIN',
      3 => 'Quick Access Ready',
      _ => 'Security PIN',
    };

    final subtitle = switch (_step) {
      0 => 'Enter your current PIN to authorize change',
      1 => 'Set a 6-digit PIN to quickly get back into Gateway',
      2 => 'Re-enter your 6-digit PIN to confirm',
      3 => 'Your 6-digit PIN has been configured successfully',
      _ => '',
    };

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon badge
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Icon(
              _step == 3
                  ? Icons.check_circle_outline_rounded
                  : Icons.lock_outline_rounded,
              color: _step == 3 ? const Color(0xFF4CAF50) : GacColors.cyan,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            title,
            style: const TextStyle(
              color: GacColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GacColors.textSecondary,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          if (_step != 3) ...[
            PinDots(
              length: _activePin.length,
              total: _step == 0 ? _expectedCurrentPinLength : 6,
              hasError: _errorMessage != null,
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: GacColors.brandRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const SizedBox(height: 16),
            const SizedBox(height: 12),
            PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: GacColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            if (_biometricsSupported) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint_rounded,
                      color: GacColors.cyan,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enable Fingerprint Scanner',
                            style: TextStyle(
                              color: GacColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Unlock quickly without typing your PIN',
                            style: TextStyle(
                              color: GacColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _biometricsEnabled,
                      activeThumbColor: GacColors.cyan,
                      onChanged: (val) =>
                          setState(() => _biometricsEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _finishSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GacColors.brandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Displays an informational guide explaining how "Remember Me" and 6-digit PIN setup work.
Future<void> showRememberMeGuideDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (modalContext) => const _RememberMeGuideSheet(),
  );
}

class _RememberMeGuideSheet extends StatelessWidget {
  const _RememberMeGuideSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: GacColors.cyan,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Stay Signed In Guide',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GacColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How Remember Me & 6-Digit PIN keep your workflow uninterrupted',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GacColors.textSecondary,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            _buildGuideCard(
              icon: Icons.check_box_outlined,
              iconColor: GacColors.cyan,
              title: '1. Check "Remember me" at Sign In',
              description: 'When checked, the app disables the standard 1-hour inactivity timeout. You stay continuously signed in without re-entering your username and password.',
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              icon: Icons.dialpad_rounded,
              iconColor: GacColors.cyan,
              title: '2. Set Up a 6-Digit PIN',
              description: 'The first time you check "Remember me", the app prompts you to create a 6-digit PIN. You can also enable your device fingerprint scanner for faster unlock.',
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              icon: Icons.notifications_active_outlined,
              iconColor: const Color(0xFF4CAF50),
              title: '3. Instant Notification & App Access',
              description: 'When opening the app or tapping notification reminders (e.g. task alerts, missed checklists), you will never be logged out. Enter your 6-digit PIN or scan fingerprint to jump right in.',
            ),
            const SizedBox(height: 12),
            _buildGuideCard(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'Standard 1-Hour Timeout (Without Remember Me)',
              description: 'If "Remember me" is unchecked, the app securely logs you out after 1 hour of inactivity. Remember Me prevents this timeout.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GacColors.brandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'GOT IT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildGuideCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: GacColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: GacColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
