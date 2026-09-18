import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'index.dart';
import 'models/authenticated_user.dart';
import 'services/local_notification_service.dart';
import 'services/security_service.dart';
import 'services/session_service.dart';
import 'services/background_notification_service.dart';
import 'services/checklist_service.dart';
import 'services/utilities_missed_checklist_service.dart';
import 'theme/gac_theme.dart';
import 'widgets/pin_dialogs.dart';

const String _adminDashboardRoute = '/(admin)/dashboard';
const String _dosDashboardRoute = '/(dos)/dashboard';

const String _rememberEmailKey = gacRememberEmailKey;

const String _rememberMeKey = gacRememberMeKey;

const String _userHomeRoute = '/(user)/home';

/// Returns the authenticated shell assigned to a Server user type.
///
/// Kept public so role routing can be covered independently of the login UI.
String destinationForUserType(String userType) {
  final normalizedType = normalizeUserType(userType).toUpperCase();

  if (normalizedType == '5S_UTILITIES' ||
      normalizedType == '5S UTILITIES' ||
      normalizedType == '5S-UTILITIES' ||
      normalizedType == '5S_SERVICE' ||
      normalizedType == '5S SERVICE' ||
      normalizedType == '5S-SERVICE' ||
      normalizedType == '5S_SALES' ||
      normalizedType == '5S SALES' ||
      normalizedType == '5S-SALES' ||
      normalizedType == 'SERVICE_5S' ||
      normalizedType == 'SALES_5S' ||
      normalizedType == 'PIC' ||
      normalizedType == 'PERSON IN CHARGE' ||
      normalizedType == 'UTILITIES' ||
      normalizedType == 'UTILITY' ||
      normalizedType == 'RESTROOM' ||
      normalizedType == 'SALES_SERVICE' ||
      normalizedType == 'SALES-SERVICE' ||
      normalizedType == 'SALES & SERVICE' ||
      normalizedType == '5S') {
    return _userHomeRoute;
  }

  if (normalizedType == 'DOS' ||
      normalizedType == 'DOS_SALES' ||
      normalizedType == 'DOS_AFTERSALES' ||
      normalizedType == 'SM' ||
      normalizedType == 'SALES MANAGER' ||
      normalizedType == 'SALES_MANAGER' ||
      normalizedType == 'SALES MGR' ||
      normalizedType == 'ASM' ||
      normalizedType == 'AFTERSALES MANAGER' ||
      normalizedType == 'AFTERSALES_MANAGER' ||
      normalizedType == 'AS MGR' ||
      normalizedType == 'CE SERVICE' ||
      normalizedType == 'CE_SERVICE' ||
      normalizedType == 'CE' ||
      normalizedType == 'JC' ||
      normalizedType == 'JOB CONTROLLER' ||
      normalizedType == 'JOB_CONTROLLER' ||
      normalizedType == 'PARTS' ||
      normalizedType == 'PARTS SUPERVISOR' ||
      normalizedType == 'PARTS_SUPERVISOR' ||
      normalizedType == 'WS SUP') {
    return _dosDashboardRoute;
  }

  if (normalizedType == 'ADMIN' ||
      normalizedType == 'GM' ||
      normalizedType == 'GENERAL MANAGER' ||
      normalizedType == 'BOM' ||
      normalizedType == 'BRANCH OPERATIONS MANAGER' ||
      normalizedType == 'BRANCH OPERATION MANAGER') {
    return _adminDashboardRoute;
  }

  throw _UnsupportedUserTypeError('Unsupported user type: $userType');
}

Future<_LoginApiResponse> _loginWithServer(
  String email,
  String password,
) async {
  final apiUrl = gacApiUrl.replaceFirst(RegExp(r'/$'), '');
  final deviceId = await notificationDeviceId();
  late final http.Response response;

  try {
    response = await http.post(
      Uri.parse('$apiUrl/login'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'notification_device_id': deviceId,
      }),
    );
  } catch (_) {
    throw _ApiRequestError(
      'Cannot connect to the server at $apiUrl. Make sure the API server is running.',
    );
  }

  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } catch (_) {
    decoded = null;
  }

  final data = _stringKeyedMap(decoded);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final errors = _validationErrors(data?['errors']);
    final firstValidationError = errors.values
        .expand((messages) => messages)
        .firstOrNull;
    final responseMessage = data?['message'];

    throw _ApiRequestError(
      firstValidationError ??
          (responseMessage is String ? responseMessage : null) ??
          'Unable to sign in.',
      errors,
    );
  }

  final token = data?['token'];
  final user = _AuthUser.fromJson(data?['user']);
  if (token is! String || user == null) {
    throw const _ApiRequestError('Server returned an invalid login response.');
  }

  return _LoginApiResponse(
    token: token,
    user: user,
    notificationToken: data?['notification_token'] as String?,
  );
}

String _messageForError(Object error) {
  if (error is _ApiRequestError) return error.message;
  if (error is _UnsupportedUserTypeError) return error.message;
  if (error is PlatformException && error.message != null) {
    return error.message!;
  }
  if (error is FormatException) return error.message;

  if (error is Exception || error is Error) {
    var message = error.toString();
    for (final prefix in const ['Exception: ', 'Bad state: ']) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length);
        break;
      }
    }
    if (message.isNotEmpty) return message;
  }

  return 'Please check your details and try again.';
}

Map<String, dynamic>? _stringKeyedMap(Object? value) {
  if (value is! Map) return null;

  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

Map<String, List<String>> _validationErrors(Object? value) {
  final data = _stringKeyedMap(value);
  if (data == null) return const {};

  final result = <String, List<String>>{};
  for (final entry in data.entries) {
    final messages = entry.value;
    if (messages is List) {
      result[entry.key] = messages.whereType<String>().toList();
    }
  }
  return result;
}

/// Flutter equivalent of `src/app/login.tsx`.
class GatewayLoginScreen extends StatefulWidget {
  /// Animates the sign-in composition after the launch splash when true.
  ///
  /// Direct and deep-link visits remain immediately interactive.
  final bool arrivedFromWelcome;

  /// Whether the user was redirected to the login screen after inactivity timeout.
  final bool fromTimeout;

  /// Overrides the built-in Server request when supplied.
  final FutureOr<void> Function(LoginCredentials credentials)? onLogin;

  /// Overrides the placeholder forgot-password alert when supplied.
  final VoidCallback? onForgotPassword;

  const GatewayLoginScreen({
    super.key,
    this.arrivedFromWelcome = false,
    this.fromTimeout = false,
    this.onLogin,
    this.onForgotPassword,
  });

  @override
  State<GatewayLoginScreen> createState() => _GatewayLoginScreenState();
}

/// The values passed to [GatewayLoginScreen.onLogin].
class LoginCredentials {
  final String login;
  final String password;
  final bool remember;
  const LoginCredentials({
    required this.login,
    required this.password,
    required this.remember,
  });
}

class _ApiRequestError implements Exception {
  final String message;
  final Map<String, List<String>> errors;
  const _ApiRequestError(this.message, [this.errors = const {}]);

  @override
  String toString() => message;
}

class _AuthUser {
  final String userType;
  final Map<String, dynamic> raw;
  const _AuthUser({required this.userType, required this.raw});

  static _AuthUser? fromJson(Object? value) {
    final data = _stringKeyedMap(value);
    if (data == null ||
        data['id'] is! int ||
        data['name'] is! String ||
        data['email'] is! String ||
        (data['branch'] != null && data['branch'] is! String) ||
        data['user_type'] is! String) {
      return null;
    }

    final userType = normalizeUserType(data['user_type'] as String);
    final normalizedData = Map<String, dynamic>.of(data)
      ..['user_type'] = userType;
    return _AuthUser(userType: userType, raw: normalizedData);
  }
}

class _FormField extends StatelessWidget {
  final String accessibilityLabel;
  final String label;
  final IconData leadingIcon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final String? error;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? rightAction;
  final double scale;
  const _FormField({
    required this.accessibilityLabel,
    required this.label,
    required this.leadingIcon,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.onChanged,
    required this.textInputAction,
    required this.autofillHints,
    required this.scale,
    this.error,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.rightAction,
  });

  @override
  Widget build(BuildContext context) {
    final fieldHeight = 54 * scale;
    final textSize = 13.5 * scale;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final borderColor = error != null
            ? GacColors.brandRed
            : focused
            ? _LoginColors.icon
            : _LoginColors.fieldBorder;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: focused ? _LoginColors.icon : _LoginColors.muted,
                fontSize: 9 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9 * scale,
              ),
            ),
            SizedBox(height: 7 * scale),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              height: fieldHeight,
              decoration: BoxDecoration(
                color: focused ? _LoginColors.fieldFocused : _LoginColors.field,
                borderRadius: BorderRadius.circular(15 * scale),
                border: Border.all(
                  color: borderColor,
                  width: error != null || focused ? 1.4 : 1,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x20000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                  if (focused)
                    const BoxShadow(color: Color(0x2200BCD4), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48 * scale,
                    height: fieldHeight,
                    child: Center(
                      child: Icon(
                        leadingIcon,
                        size: 19 * scale,
                        color: focused
                            ? _LoginColors.icon
                            : _LoginColors.placeholder,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: fieldHeight,
                      child: Semantics(
                        label: accessibilityLabel,
                        textField: true,
                        child: TextSelectionTheme(
                          data: const TextSelectionThemeData(
                            cursorColor: _LoginColors.icon,
                            selectionColor: Color(0x4400BCD4),
                            selectionHandleColor: _LoginColors.icon,
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            keyboardType: keyboardType,
                            textInputAction: textInputAction,
                            obscureText: obscureText,
                            textAlignVertical: TextAlignVertical.center,
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: autofillHints,
                            cursorColor: _LoginColors.icon,
                            cursorHeight: 18 * scale,
                            style: TextStyle(
                              color: _LoginColors.inputText,
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 18 * scale,
                              ),
                              hintText: placeholder,
                              hintStyle: TextStyle(
                                color: _LoginColors.placeholder,
                                fontSize: textSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onChanged: onChanged,
                            onSubmitted: onSubmitted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ?rightAction,
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: EdgeInsets.only(left: 8 * scale, top: 5 * scale),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: GacColors.red800,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GatewayLoginScreenState extends State<GatewayLoginScreen>
    with SingleTickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 1550);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  late final AnimationController _entranceController;
  bool _entranceStarted = false;

  bool _showPassword = false;
  bool _loading = false;
  bool _rememberMe = false;
  bool _logoHeroEnabled = true;
  String? _loginError;
  String? _passwordError;

  bool _isQuickUnlock = false;
  String _quickUnlockPin = '';
  String? _quickUnlockError;
  _AuthUser? _quickUnlockUser;
  Map<String, dynamic>? _quickUnlockUserData;
  bool _biometricAvailable = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: _LoginColors.page,
        systemNavigationBarColor: _LoginColors.page,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: _LoginColors.page,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const GatewayBlushBackdrop(),
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, _) => SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = (constraints.maxWidth / 390)
                        .clamp(0.88, 1.08)
                        .toDouble();
                    final horizontalPadding = constraints.maxWidth < 360
                        ? 18.0
                        : 24.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(0, constraints.maxHeight - 32),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildLoginContent(scale: scale),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginContent({required double scale}) {
    final headerEntrance = _entrancePhase(
      beginMilliseconds: 550,
      endMilliseconds: 1150,
      curve: const Cubic(0.22, 0.61, 0.36, 1),
    );
    final cardEntrance = _entrancePhase(
      beginMilliseconds: 670,
      endMilliseconds: 1420,
      curve: const Cubic(0.22, 0.61, 0.36, 1),
    );
    final footerEntrance = _entrancePhase(
      beginMilliseconds: 950,
      endMilliseconds: 1550,
      curve: Curves.ease,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroMode(
          enabled: _logoHeroEnabled,
          child: Hero(
            tag: gatewayLogoHeroTag,
            child: GatewayLogoBadge(
              key: const ValueKey('gateway-login-logo'),
              size: 180 * scale,
              imageScale: 0.82,
            ),
          ),
        ),
        SizedBox(height: 18 * scale),
        _LoginEntrance(
          progress: headerEntrance,
          offsetY: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isQuickUnlock ? 'Welcome Back' : 'Sign In',
                key: const ValueKey('gateway-login-title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _LoginColors.ink,
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3 * scale,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                _isQuickUnlock
                    ? (_quickUnlockUserData?['name'] as String? ??
                          'Authorized Personnel')
                    : 'Audit Compliance App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isQuickUnlock
                      ? _LoginColors.brand
                      : _LoginColors.muted,
                  fontSize: _isQuickUnlock ? 14 * scale : 12 * scale,
                  fontWeight: _isQuickUnlock
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: 0.1 * scale,
                ),
              ),
              if (_isQuickUnlock) ...[
                SizedBox(height: 4 * scale),
                Text(
                  'Enter your 4-digit PIN to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _LoginColors.muted,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 24 * scale),
        _LoginEntrance(
          progress: cardEntrance,
          offsetY: 26,
          child: _LoginCard(
            child: Padding(
              padding: EdgeInsets.all(22 * scale),
              child: _isQuickUnlock
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PinDots(
                          length: _quickUnlockPin.length,
                          hasError: _quickUnlockError != null,
                        ),
                        SizedBox(height: 10 * scale),
                        if (_quickUnlockError != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 8 * scale),
                            child: Text(
                              _quickUnlockError!,
                              style: const TextStyle(
                                color: GacColors.brandRed,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          SizedBox(height: 12 * scale),
                        PinKeypad(
                          onDigit: _onQuickUnlockDigit,
                          onBackspace: _onQuickUnlockBackspace,
                          showBiometric: _biometricAvailable,
                          onBiometric: _attemptBiometricUnlock,
                        ),
                        SizedBox(height: 16 * scale),
                        _PressSurface(
                          onTap: _exitQuickUnlock,
                          semanticLabel: 'Sign in with password',
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Text(
                              'Sign in with password instead',
                              style: TextStyle(
                                color: _LoginColors.brand,
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _ScaledLoginForm(
                      scale: scale,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      emailFocusNode: _emailFocusNode,
                      passwordFocusNode: _passwordFocusNode,
                      showPassword: _showPassword,
                      loading: _loading,
                      rememberMe: _rememberMe,
                      loginError: _loginError,
                      passwordError: _passwordError,
                      onEmailChanged: (_) {
                        if (_loginError != null) {
                          setState(() => _loginError = null);
                        }
                      },
                      onPasswordChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                      onTogglePassword: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      onToggleRememberMe: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                          _saveRememberMe();
                        });
                      },
                      onEmailSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                      onPasswordSubmitted: (_) => _handleLogin(),
                      onForgotPassword: _handleForgotPassword,
                      onLogin: _handleLogin,
                    ),
            ),
          ),
        ),
        SizedBox(height: 22 * scale),
        _LoginEntrance(
          progress: footerEntrance,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gateway Motors Cebu Inc.',
                style: TextStyle(
                  color: _LoginColors.ink,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                'GAC Mobile v1.0.0',
                style: TextStyle(
                  color: _LoginColors.muted,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _entrancePhase({
    required int beginMilliseconds,
    required int endMilliseconds,
    required Curve curve,
  }) {
    final milliseconds =
        _entranceController.value * _entranceDuration.inMilliseconds;
    final linear =
        ((milliseconds - beginMilliseconds) /
                (endMilliseconds - beginMilliseconds))
            .clamp(0.0, 1.0);
    return curve.transform(linear);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;

    if (!widget.arrivedFromWelcome || MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
      value: widget.arrivedFromWelcome ? 0 : 1,
    );
    _loadRememberMe();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.fromTimeout) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your session timed out due to inactivity. Please sign in again.',
            ),
            backgroundColor: GacColors.navy950,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        unawaited(_checkAutoLogin());
      }
    });
  }

  void _handleForgotPassword() {
    final forgotPasswordOverride = widget.onForgotPassword;
    if (forgotPasswordOverride != null) {
      forgotPasswordOverride();
      return;
    }

    unawaited(
      _showAlert(
        'Forgot password',
        'Connect the onForgotPassword callback to your recovery screen.',
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_loading) return;
    if (!_validate()) return;

    try {
      setState(() => _loading = true);

      final credentials = LoginCredentials(
        login: _emailController.text.trim(),
        password: _passwordController.text,
        remember: _rememberMe,
      );

      final loginOverride = widget.onLogin;
      if (loginOverride != null) {
        await loginOverride(credentials);
        SessionManager.instance.startTracking(isRemembered: _rememberMe);
      } else {
        final result = await _loginWithServer(
          credentials.login,
          credentials.password,
        );
        final destination = destinationForUserType(result.user.userType);

        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(gacAuthTokenKey, result.token);
        await preferences.setString(
          gacAuthUserKey,
          jsonEncode(result.user.raw),
        );

        final normalizedUserType = result.user.userType.trim().toUpperCase();
        await preferences.setString(gacPreviousUserTypeKey, normalizedUserType);
        // Persist full role details and sync role-based notification schedule immediately
        try {
          final authUser = AuthenticatedUser.fromJson(result.user.raw);
          await LocalNotificationService.instance.recordPreviousUser(
            authUser,
            token: result.token,
            rememberMe: _rememberMe,
            notificationToken: result.notificationToken,
            replaceNotificationAccount: true,
          );
        } catch (_) {
          await LocalNotificationService.instance.recordPreviousRole(
            userType: result.user.userType,
          );
        }
        await LocalNotificationService.instance.syncForPreviousUser();
        await startBackgroundNotificationPolling();

        final authUser = AuthenticatedUser.fromJson(result.user.raw);
        if (authUser.is5sUtilities || authUser.isUtilities) {
          unawaited(
            UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
              repository: ChecklistApiService(),
              user: authUser,
            ).catchError((_) => null),
          );
        }

        final userEmail =
            (result.user.raw['email'] as String?)?.trim() ??
            credentials.login.trim();

        if (_rememberMe) {
          final hasPin = await SecurityService.instance.hasPin(
            email: userEmail,
          );
          if (!hasPin && mounted) {
            final created = await showPinSetupDialog(context, email: userEmail);
            if (!created) {
              // User dismissed without setting PIN: cancel Remember Me
              _rememberMe = false;
            }
          }
        }

        // Save remember me preference on successful login
        await _saveRememberMe();

        // Start session tracking: non-remembered users will timeout after inactivity
        SessionManager.instance.startTracking(isRemembered: _rememberMe);
        LocalNotificationService.instance
            .stopTimedOutManagerNotificationPolling();

        final pendingPayload = await LocalNotificationService.instance
            .consumePendingPayload();
        String targetDestination = destination;
        Object? targetArguments;
        if (pendingPayload != null &&
            (destination == _userHomeRoute ||
                (destination == _dosDashboardRoute &&
                    (pendingPayload.event == 'dos_month_end_due' ||
                        pendingPayload.targetsDosChecklist)))) {
          targetDestination = destination == _dosDashboardRoute
              ? '/(dos)/audit'
              : '/(user)/checklists';
          targetArguments = {
            'template_slug': pendingPayload.templateSlug,
            'slot_key': pendingPayload.slotKey,
            'audit_date': pendingPayload.auditDate,
            'submission_id': pendingPayload.submissionId,
            'item_key': pendingPayload.itemKey,
            'customer_index': pendingPayload.customerIndex,
          };
        }

        if (!mounted) return;
        if (result.user.raw['must_change_password'] == true) {
          await _openDestination(
            '/force-password-change',
            arguments: {
              'currentPassword': credentials.password,
              'destination': targetDestination,
              'destinationArguments': targetArguments,
              'rememberMe': _rememberMe,
            },
          );
          return;
        }

        await _openDestination(targetDestination, arguments: targetArguments);
      }
    } on _ApiRequestError catch (error) {
      if (!mounted) return;
      setState(() {
        _loginError =
            error.errors['email']?.firstOrNull ??
            error.errors['login']?.firstOrNull;
        _passwordError = error.errors['password']?.firstOrNull;
      });
      unawaited(_showAlert('Unable to sign in', error.message));
    } catch (error) {
      if (!mounted) return;
      unawaited(_showAlert('Unable to sign in', _messageForError(error)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final remember = prefs.getBool(_rememberMeKey) ?? false;
      final email = prefs.getString(_rememberEmailKey) ?? '';

      if (mounted) {
        setState(() {
          _rememberMe = remember;
          if (remember && email.isNotEmpty) {
            _emailController.text = email;
          } else {
            _emailController.clear();
          }
          _passwordController.clear();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(_rememberEmailKey, _emailController.text.trim());
      } else {
        await prefs.remove(_rememberEmailKey);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Check for existing session and handle quick PIN/biometric unlock or auto-login
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      final token = prefs.getString(gacAuthTokenKey);
      final userJson = prefs.getString(gacAuthUserKey);

      if (rememberMe && token != null && userJson != null) {
        final userData = jsonDecode(userJson);
        final user = _AuthUser.fromJson(userData);

        if (user != null && mounted) {
          if (userData is Map && userData['user_type'] != user.userType) {
            await prefs.setString(gacAuthUserKey, jsonEncode(user.raw));
          }
          final userEmail =
              (user.raw['email'] as String?)?.trim() ??
              prefs.getString(_rememberEmailKey)?.trim();
          final hasPin = await SecurityService.instance.hasPin(
            email: userEmail,
          );
          if (hasPin) {
            final supported = await SecurityService.instance
                .isBiometricsSupported();
            final enabled = await SecurityService.instance
                .isBiometricsEnabled();
            setState(() {
              _isQuickUnlock = true;
              _quickUnlockUser = user;
              _quickUnlockUserData = user.raw;
              _quickUnlockPin = '';
              _quickUnlockError = null;
              _biometricAvailable = supported && enabled;
            });
            if (_biometricAvailable) {
              unawaited(_attemptBiometricUnlock());
            }
            return;
          }

          SessionManager.instance.startTracking(isRemembered: true);
          final authUser = AuthenticatedUser.fromJson(user.raw);
          if (authUser.is5sUtilities || authUser.isUtilities) {
            unawaited(
              UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
                repository: ChecklistApiService(),
                user: authUser,
              ).catchError((_) => null),
            );
          }
          final destination = destinationForUserType(user.userType);
          final pendingPayload = await LocalNotificationService.instance
              .consumePendingPayload();
          String targetDestination = destination;
          Object? targetArguments;
          if (pendingPayload != null &&
              (destination == _userHomeRoute ||
                  (destination == _dosDashboardRoute &&
                      (pendingPayload.event == 'dos_month_end_due' ||
                          pendingPayload.targetsDosChecklist)))) {
            targetDestination = destination == _dosDashboardRoute
                ? '/(dos)/audit'
                : '/(user)/checklists';
            targetArguments = {
              'template_slug': pendingPayload.templateSlug,
              'slot_key': pendingPayload.slotKey,
              'audit_date': pendingPayload.auditDate,
              'submission_id': pendingPayload.submissionId,
              'item_key': pendingPayload.itemKey,
              'customer_index': pendingPayload.customerIndex,
            };
          }
          if (user.raw['must_change_password'] == true) {
            await _openDestination(
              '/force-password-change',
              arguments: {
                'destination': targetDestination,
                'destinationArguments': targetArguments,
                'rememberMe': true,
              },
            );
            return;
          }

          await _openDestination(targetDestination, arguments: targetArguments);
        }
      }
    } catch (e) {
      // Silently handle auto-login errors - user will see login screen
    }
  }

  Future<void> _attemptBiometricUnlock() async {
    final authenticated = await SecurityService.instance
        .authenticateWithBiometrics(
          reason: 'Scan your fingerprint to unlock Gateway Audit Compliance',
        );
    if (authenticated && mounted && _isQuickUnlock) {
      SessionManager.instance.startTracking(isRemembered: true);
      await _proceedFromQuickUnlock();
    }
  }

  void _onQuickUnlockDigit(String digit) {
    if (_quickUnlockPin.length >= 4) return;
    setState(() {
      _quickUnlockPin += digit;
      _quickUnlockError = null;
    });
    if (_quickUnlockPin.length == 4) {
      unawaited(_verifyQuickUnlockPin());
    }
  }

  void _onQuickUnlockBackspace() {
    if (_quickUnlockPin.isNotEmpty) {
      setState(() {
        _quickUnlockPin = _quickUnlockPin.substring(
          0,
          _quickUnlockPin.length - 1,
        );
        _quickUnlockError = null;
      });
    }
  }

  Future<void> _verifyQuickUnlockPin() async {
    final userEmail =
        (_quickUnlockUser?.raw['email'] as String?)?.trim() ??
        (_quickUnlockUserData?['email'] as String?)?.trim();
    final valid = await SecurityService.instance.verifyPin(
      _quickUnlockPin,
      email: userEmail,
    );
    if (!mounted) return;
    if (valid) {
      SessionManager.instance.startTracking(isRemembered: true);
      await _proceedFromQuickUnlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _quickUnlockError = 'Incorrect PIN. Try again.';
        _quickUnlockPin = '';
      });
    }
  }

  Future<void> _proceedFromQuickUnlock() async {
    final user = _quickUnlockUser;
    if (user == null || !mounted) return;
    LocalNotificationService.instance.stopTimedOutManagerNotificationPolling();
    final authUser = AuthenticatedUser.fromJson(user.raw);
    if (authUser.is5sUtilities || authUser.isUtilities) {
      unawaited(
        UtilitiesMissedChecklistService.syncMissedUtilitiesChecklist(
          repository: ChecklistApiService(),
          user: authUser,
        ).catchError((_) => null),
      );
    }
    final destination = destinationForUserType(user.userType);
    final pendingPayload = await LocalNotificationService.instance
        .consumePendingPayload();
    String targetDestination = destination;
    Object? targetArguments;
    if (pendingPayload != null &&
        (destination == _userHomeRoute ||
            (destination == _dosDashboardRoute &&
                (pendingPayload.event == 'dos_month_end_due' ||
                    pendingPayload.targetsDosChecklist)))) {
      targetDestination = destination == _dosDashboardRoute
          ? '/(dos)/audit'
          : '/(user)/checklists';
      targetArguments = {
        'template_slug': pendingPayload.templateSlug,
        'slot_key': pendingPayload.slotKey,
        'audit_date': pendingPayload.auditDate,
        'submission_id': pendingPayload.submissionId,
        'item_key': pendingPayload.itemKey,
        'customer_index': pendingPayload.customerIndex,
      };
    }
    if (user.raw['must_change_password'] == true) {
      await _openDestination(
        '/force-password-change',
        arguments: {
          'destination': targetDestination,
          'destinationArguments': targetArguments,
          'rememberMe': true,
        },
      );
      return;
    }

    await _openDestination(targetDestination, arguments: targetArguments);
  }

  void _exitQuickUnlock() {
    setState(() {
      _isQuickUnlock = false;
      _quickUnlockPin = '';
      _quickUnlockError = null;
    });
  }

  Future<void> _openDestination(String destination, {Object? arguments}) async {
    await _waitForRouteEntrance();
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    if (_logoHeroEnabled) {
      setState(() => _logoHeroEnabled = false);
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) return;
    await Navigator.of(context)
        .pushReplacementNamed<void, void>(destination, arguments: arguments);
  }

  Future<void> _waitForRouteEntrance() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.status == AnimationStatus.completed) {
      return;
    }

    final completer = Completer<void>();
    void completeWhenSettled(AnimationStatus status) {
      if ((status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) &&
          !completer.isCompleted) {
        completer.complete();
      }
    }

    animation.addStatusListener(completeWhenSettled);
    completeWhenSettled(animation.status);
    await completer.future;
    animation.removeStatusListener(completeWhenSettled);
  }

  Future<void> _showAlert(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
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

  bool _validate() {
    final email = _emailController.text.trim();
    String? loginError;
    String? passwordError;

    if (email.isEmpty) {
      loginError = 'Enter your email address.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      loginError = 'Enter a valid email address.';
    }

    if (_passwordController.text.isEmpty) {
      passwordError = 'Enter your password.';
    }

    setState(() {
      _loginError = loginError;
      _passwordError = passwordError;
    });

    return loginError == null && passwordError == null;
  }
}

class _LoginApiResponse {
  final String token;
  final _AuthUser user;
  final String? notificationToken;
  const _LoginApiResponse({
    required this.token,
    required this.user,
    this.notificationToken,
  });
}

class _LoginEntrance extends StatelessWidget {
  final Widget child;
  final double progress;
  final double offsetY;

  const _LoginEntrance({
    required this.child,
    required this.progress,
    this.offsetY = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: progress < 1,
      child: ExcludeSemantics(
        excluding: progress == 0,
        child: Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - progress)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final Widget child;

  const _LoginCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xB30D1B2A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x331A5C8C), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

abstract final class _LoginColors {
  static const page = Color(0xFF0A1628);
  static const ink = Color(0xFFE8EDF2);
  static const brand = Color(0xFF2979FF);
  static const icon = Color(0xFF00BCD4);
  static const inputText = Color(0xFFE8EDF2);
  static const placeholder = Color(0xFF5C7A99);
  static const muted = Color(0xFF8899AA);
  static const field = Color(0xFF0D2137);
  static const fieldFocused = Color(0xFF122A42);
  static const fieldBorder = Color(0xFF1A3A5C);
}

class _PressSurface extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;
  final bool enabled;
  final double disabledOpacity;
  const _PressSurface({
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.enabled = true,
    this.disabledOpacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: enabled,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Opacity(opacity: enabled ? 1 : disabledOpacity, child: child),
        ),
      ),
    );
  }
}

class _ScaledLoginForm extends StatelessWidget {
  final double scale;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool showPassword;
  final bool loading;
  final bool rememberMe;
  final String? loginError;
  final String? passwordError;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRememberMe;
  final ValueChanged<String> onEmailSubmitted;
  final ValueChanged<String> onPasswordSubmitted;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  const _ScaledLoginForm({
    required this.scale,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.showPassword,
    required this.loading,
    required this.rememberMe,
    required this.loginError,
    required this.passwordError,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleRememberMe,
    required this.onEmailSubmitted,
    required this.onPasswordSubmitted,
    required this.onForgotPassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FormField(
          accessibilityLabel: 'Email address',
          label: 'Email address',
          leadingIcon: Icons.person_outline_rounded,
          controller: emailController,
          focusNode: emailFocusNode,
          placeholder: 'name@gateway.com',
          error: loginError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onChanged: onEmailChanged,
          onSubmitted: onEmailSubmitted,
          scale: scale,
        ),
        SizedBox(height: (loginError == null ? 14 : 10) * scale),
        _FormField(
          accessibilityLabel: 'Password',
          label: 'Password',
          leadingIcon: Icons.lock_outline_rounded,
          controller: passwordController,
          focusNode: passwordFocusNode,
          placeholder: 'Enter password',
          error: passwordError,
          obscureText: !showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: onPasswordChanged,
          onSubmitted: onPasswordSubmitted,
          scale: scale,
          rightAction: _PressSurface(
            onTap: onTogglePassword,
            semanticLabel: showPassword ? 'Hide password' : 'Show password',
            child: SizedBox(
              width: 48 * scale,
              height: 54 * scale,
              child: Center(
                child: Icon(
                  showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18 * scale,
                  color: _LoginColors.placeholder,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: (passwordError == null ? 14 : 10) * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _PressSurface(
                onTap: onToggleRememberMe,
                semanticLabel: 'Remember me',
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4 * scale),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18 * scale,
                        height: 18 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4 * scale),
                          color: rememberMe
                              ? _LoginColors.brand
                              : Colors.transparent,
                          border: Border.all(
                            color: rememberMe
                                ? _LoginColors.brand
                                : _LoginColors.placeholder,
                            width: 1.4,
                          ),
                        ),
                        child: rememberMe
                            ? Icon(
                                Icons.check_rounded,
                                size: 13 * scale,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      SizedBox(width: 7 * scale),
                      Flexible(
                        child: Text(
                          'Remember me',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _LoginColors.ink,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PressSurface(
              onTap: onForgotPassword,
              semanticLabel: 'Forgot password?',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4 * scale),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: _LoginColors.brand,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 15 * scale,
              color: const Color(0xFF4CAF50),
            ),
            SizedBox(width: 7 * scale),
            Expanded(
              child: Text(
                'Authorized Pickup Personnel and Security Guards only.',
                style: TextStyle(
                  color: _LoginColors.muted,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20 * scale),
        _PressSurface(
          onTap: onLogin,
          enabled: !loading,
          disabledOpacity: 0.68,
          semanticLabel: 'Sign in',
          child: Container(
            height: 52 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _LoginColors.brand,
              borderRadius: BorderRadius.circular(14 * scale),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3E2979FF),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18 * scale,
                  color: Colors.white,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  loading ? 'SIGNING IN...' : 'SIGN IN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5 * scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnsupportedUserTypeError implements Exception {
  final String message;
  const _UnsupportedUserTypeError(this.message);

  @override
  String toString() => message;
}
