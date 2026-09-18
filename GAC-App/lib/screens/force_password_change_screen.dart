import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../index.dart';
import '../services/profile_service.dart';
import '../services/security_service.dart';
import '../services/session_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/pin_dialogs.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  final String? currentPassword;
  final String destination;
  final Object? destinationArguments;
  final bool rememberMe;
  final ProfileRepository? profileRepository;

  const ForcePasswordChangeScreen({
    super.key,
    this.currentPassword,
    required this.destination,
    this.destinationArguments,
    this.rememberMe = false,
    this.profileRepository,
  });

  @override
  State<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocusNode = FocusNode();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitting = false;
  String? _errorMessage;

  late final ProfileRepository _profileRepository;

  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? ProfileApiService();
    _currentPasswordController = TextEditingController(
      text: widget.currentPassword ?? 'Gateway@2026',
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await _profileRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      // Update cached user in SharedPreferences so must_change_password is now false
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(gacAuthUserKey);
      if (userJson != null) {
        try {
          final userMap = Map<String, dynamic>.from(
            prefs.getString(gacAuthUserKey) != null
                ? (await _profileRepository.loadCachedProfile())?.toJson() ?? {}
                : {},
          );
          userMap['must_change_password'] = false;
        } catch (_) {}
      }

      // If user had Remember Me enabled, prompt for PIN setup if they don't have one
      if (widget.rememberMe) {
        final profile = await _profileRepository.loadCachedProfile();
        final userEmail = profile?.email ?? '';
        if (userEmail.isNotEmpty) {
          final hasPin = await SecurityService.instance.hasPin(email: userEmail);
          if (!hasPin && mounted) {
            await showPinSetupDialog(context, email: userEmail);
          }
        }
      }

      SessionManager.instance.startTracking(isRemembered: widget.rememberMe);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Welcome to Gateway!'),
          backgroundColor: GacColors.green800,
          duration: Duration(seconds: 3),
        ),
      );

      await Navigator.of(context).pushReplacementNamed<void, void>(
        widget.destination,
        arguments: widget.destinationArguments,
      );
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _profileRepository.logout();
    } catch (_) {}
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: const Color(0xFF0A1628),
          systemNavigationBarColor: const Color(0xFF0A1628),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const GatewayBlushBackdrop(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF102847),
                              border: Border.all(
                                color: const Color(0xFF00BCD4),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3300BCD4),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 36,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Password Change Required',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFE8EDF2),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your account was created with a temporary default password. Please choose a new, secure password to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8899AA),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xB30D1B2A),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0x331A5C8C),
                                    width: 1.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x40000000),
                                      blurRadius: 28,
                                      offset: Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_errorMessage != null) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0x22E71D48),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: GacColors.brandRed,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: GacColors.brandRed,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFDE8ED),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildField(
                                        label: 'CURRENT TEMPORARY PASSWORD',
                                        controller: _currentPasswordController,
                                        focusNode: _currentFocusNode,
                                        obscure: !_showCurrent,
                                        placeholder: 'Gateway@2026',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        onToggleObscure: () => setState(
                                          () => _showCurrent = !_showCurrent,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) =>
                                            _newFocusNode.requestFocus(),
                                        validator: (val) =>
                                            (val == null || val.trim().isEmpty)
                                                ? 'Enter your current password.'
                                                : null,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildField(
                                        label: 'NEW PASSWORD',
                                        controller: _newPasswordController,
                                        focusNode: _newFocusNode,
                                        obscure: !_showNew,
                                        placeholder: 'At least 8 characters',
                                        prefixIcon: Icons.password_rounded,
                                        onToggleObscure: () => setState(
                                          () => _showNew = !_showNew,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) =>
                                            _confirmFocusNode.requestFocus(),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Enter your new password.';
                                          }
                                          if (val.length < 8) {
                                            return 'Password must be at least 8 characters.';
                                          }
                                          if (val ==
                                              _currentPasswordController.text) {
                                            return 'New password must be different from current password.';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _buildField(
                                        label: 'CONFIRM NEW PASSWORD',
                                        controller: _confirmPasswordController,
                                        focusNode: _confirmFocusNode,
                                        obscure: !_showConfirm,
                                        placeholder: 'Re-type your new password',
                                        prefixIcon: Icons.password_rounded,
                                        onToggleObscure: () => setState(
                                          () => _showConfirm = !_showConfirm,
                                        ),
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _handleSubmit(),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Confirm your new password.';
                                          }
                                          if (val !=
                                              _newPasswordController.text) {
                                            return 'Passwords do not match.';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed:
                                              _submitting ? null : _handleSubmit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2979FF),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0x662979FF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: _submitting
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Update Password & Continue',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _submitting ? null : _handleSignOut,
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: Color(0xFF8899AA),
                            ),
                            label: const Text(
                              'Sign Out Instead',
                              style: TextStyle(
                                color: Color(0xFF8899AA),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscure,
    required String placeholder,
    required IconData prefixIcon,
    required VoidCallback onToggleObscure,
    required TextInputAction textInputAction,
    required ValueChanged<String> onSubmitted,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8899AA),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          cursorColor: const Color(0xFF00BCD4),
          style: const TextStyle(
            color: Color(0xFFE8EDF2),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF0D2137),
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color(0xFF5C7A99),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: const Color(0xFF5C7A99),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xFF5C7A99),
              ),
              onPressed: onToggleObscure,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1A3A5C),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1A3A5C),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF00BCD4),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: GacColors.brandRed,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: GacColors.brandRed,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: GacColors.brandRed,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
