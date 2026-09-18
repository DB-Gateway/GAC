import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/authenticated_user.dart';
import '../services/profile_service.dart';
import '../theme/gac_theme.dart';
import '../widgets/gac_surfaces.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_floating_header.dart';
import 'user_settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    this.initialProfile,
    this.repository,
    this.pickAvatar,
    this.onProfileUpdated,
    this.onOpenSettings,
    this.onSignOut,
    this.onBack,
    this.onOpenNotifications,
    this.unreadNotifications = 0,
    this.welcomeRoute = '/',
    super.key,
  });

  final AuthenticatedUser? initialProfile;
  final ProfileRepository? repository;
  final Future<XFile?> Function()? pickAvatar;
  final ValueChanged<AuthenticatedUser>? onProfileUpdated;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSignOut;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifications;
  final int unreadNotifications;
  final String welcomeRoute;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late ProfileRepository _repository;
  late AuthenticatedUser _profile;
  late final ScrollController _scrollController;
  bool _topBarExpanded = true;
  bool _loading = true;
  bool _avatarBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProfileApiService();
    _profile = widget.initialProfile ?? AuthenticatedUser.fallback;
    _loading = widget.initialProfile == null;
    _scrollController = ScrollController()..addListener(_handleScroll);
    unawaited(_loadProfile());
  }

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? ProfileApiService();
    }
    final incoming = widget.initialProfile;
    if (incoming != null && incoming != oldWidget.initialProfile) {
      _profile = incoming;
    }
  }

  Future<void> _loadProfile() async {
    try {
      if (widget.initialProfile == null) {
        final cached = await _repository.loadCachedProfile();
        if (cached != null && mounted) _applyProfile(cached, notify: false);
      }
      final fresh = await _repository.fetchProfile();
      if (!mounted) return;
      _applyProfile(fresh);
      setState(() {
        _loading = false;
        _error = null;
      });
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your profile could not be refreshed from Server.';
      });
    }
  }

  void _applyProfile(AuthenticatedUser profile, {bool notify = true}) {
    if (!mounted) return;
    setState(() => _profile = profile);
    if (notify) widget.onProfileUpdated?.call(profile);
  }

  Future<void> _editProfile() async {
    final profile = await showModalBottomSheet<AuthenticatedUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EditProfileSheet(profile: _profile, repository: _repository),
    );
    if (profile == null || !mounted) return;
    _applyProfile(profile);
    _showMessage('Profile information updated.');
  }

  Future<void> _changePassword() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordSheet(repository: _repository),
    );
    if (changed == true && mounted) {
      _showMessage('Password updated successfully.');
    }
  }

  Future<void> _chooseAvatar() async {
    if (_avatarBusy) return;
    try {
      final file =
          await (widget.pickAvatar?.call() ??
              ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 88,
                maxWidth: 1440,
              ));
      if (file == null || !mounted) return;
      setState(() => _avatarBusy = true);
      final profile = await _repository.uploadAvatar(
        bytes: await file.readAsBytes(),
        filename: file.name,
      );
      if (!mounted) return;
      _applyProfile(profile);
      _showMessage('Profile photo updated.');
    } on ProfileApiException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } on PlatformException {
      if (mounted) {
        _showMessage(
          'Photo access is unavailable on this device.',
          error: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('The selected photo could not be uploaded.', error: true);
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy || _profile.avatarUrl == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text('Your initials will be shown in its place.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _avatarBusy = true);
    try {
      final profile = await _repository.deleteAvatar();
      if (!mounted) return;
      _applyProfile(profile);
      _showMessage('Profile photo removed.');
    } on ProfileApiException catch (error) {
      if (mounted) _showMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _openSettings() {
    if (widget.onOpenSettings case final callback?) {
      callback();
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const UserSettingsScreen()),
    );
  }

  void _signOut() {
    if (widget.onSignOut case final callback?) {
      callback();
      return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil(widget.welcomeRoute, (_) => false);
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? GacColors.navy950 : GacColors.green900,
        ),
      );
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.userScrollDirection == ScrollDirection.idle &&
        position.pixels > 8) {
      return;
    }

    final shouldExpand =
        position.pixels <= 8 ||
        position.userScrollDirection == ScrollDirection.forward;
    if (shouldExpand == _topBarExpanded) return;
    setState(() => _topBarExpanded = shouldExpand);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleOpenNotifications() {
    widget.onOpenNotifications?.call();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomClearance = MediaQuery.viewPaddingOf(context).bottom;
    final isHomeTabOnly = widget.onBack != null;
    final bottomPadding = isHomeTabOnly
        ? (24 + bottomClearance)
        : (UserProfileFloatingHeader.extent + 36 + bottomClearance);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: GacColors.canvas,
        systemNavigationBarColor: GacColors.canvas,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GacScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 380
                    ? 16.0
                    : 20.0;
                return Stack(
                  children: [
                    RefreshIndicator(
                      edgeOffset: UserProfileFloatingHeader.extent,
                      onRefresh: _loadProfile,
                      child: ListView(
                        key: const PageStorageKey<String>('user-profile-scroll'),
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          UserProfileFloatingHeader.extent + 12,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _PageHeading(),
                                  if (_loading) ...[
                                    const SizedBox(height: 12),
                                    const LinearProgressIndicator(minHeight: 2),
                                  ],
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    _ErrorBanner(
                                      message: _error!,
                                      onRetry: _loadProfile,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _ProfileCard(
                                    profile: _profile,
                                    avatarBusy: _avatarBusy,
                                    onEditPhoto: _chooseAvatar,
                                    onRemovePhoto: _profile.avatarUrl == null
                                        ? null
                                        : _removeAvatar,
                                    onEditProfile: _editProfile,
                                  ),
                                  const SizedBox(height: 14),
                                  _DetailsCard(profile: _profile),
                                  const SizedBox(height: 14),
                                  _ActionCard(
                                    key: const ValueKey('change-password-action'),
                                    title: 'Change password',
                                    description: 'Verify your current password and create a new one',
                                    icon: Icons.lock_reset_rounded,
                                    onPressed: _changePassword,
                                  ),
                                  const SizedBox(height: 10),
                                  _ActionCard(
                                    title: 'Workspace settings',
                                    description: 'Notifications, reminders, and display preferences',
                                    icon: Icons.settings_outlined,
                                    onPressed: _openSettings,
                                  ),
                                  const SizedBox(height: 14),
                                  _SignOutButton(onPressed: _signOut),
                                  const SizedBox(height: 19),
                                  const Text(
                                    'Gateway Audit Compliance · Mobile v1.0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: GacColors.slate,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: UserProfileFloatingHeader.extent,
                      child: UserProfileFloatingHeader(
                        expanded: _topBarExpanded,
                        user: _profile,
                        title: 'Profile',
                        subtitle: 'Audit Compliance App',
                        onBack: widget.onBack,
                        onOpenNotifications: _handleOpenNotifications,
                        onTapTitle: _scrollToTop,
                        unreadNotifications: widget.unreadNotifications,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MY ACCOUNT',
        style: TextStyle(
          color: GacColors.cyan,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.7,
        ),
      ),
      SizedBox(height: 5),
      Text(
        'Profile',
        style: TextStyle(
          color: GacColors.textPrimary,
          fontSize: 29,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GacContentPanel(
    color: const Color(0x242979FF),
    borderColor: GacColors.cardBorder,
    borderRadius: 15,
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: GacColors.cyan),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: GacColors.navy950,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.avatarBusy,
    required this.onEditPhoto,
    required this.onRemovePhoto,
    required this.onEditProfile,
  });

  final AuthenticatedUser profile;
  final bool avatarBusy;
  final VoidCallback onEditPhoto;
  final VoidCallback? onRemovePhoto;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) => GacGlassSurface(
    padding: const EdgeInsets.all(22),
    borderRadius: 24,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: GacColors.glassShadow,
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: UserAvatar(
                user: profile,
                size: 92,
                borderColor: GacColors.white,
                borderWidth: 3,
              ),
            ),
            Positioned(
              right: -4,
              bottom: 1,
              child: Material(
                color: GacColors.primary,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  key: const ValueKey('edit-profile-photo'),
                  onTap: avatarBusy ? null : onEditPhoto,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 34,
                    child: Center(
                      child: avatarBusy
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: GacColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              color: GacColors.white,
                              size: 17,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GacColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          profile.assignmentLabel.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GacColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        const _ActiveAccountBadge(),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('edit-profile-information'),
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit information'),
            ),
            if (onRemovePhoto != null)
              TextButton.icon(
                onPressed: avatarBusy ? null : onRemovePhoto,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Remove photo'),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ActiveAccountBadge extends StatelessWidget {
  const _ActiveAccountBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x26249D6B),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x40249D6B)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: GacColors.green600,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 6),
        Text(
          'ACTIVE ACCOUNT',
          style: TextStyle(
            color: GacColors.green200,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile});

  final AuthenticatedUser profile;

  @override
  Widget build(BuildContext context) {
    final details = [
      _DetailData('Email address', profile.email, Icons.mail_outline_rounded),
      _DetailData(
        'Assigned branch',
        profile.branch ?? 'Not assigned',
        Icons.business_outlined,
      ),
      _DetailData(
        'Account type',
        profile.roleLabel,
        Icons.verified_user_outlined,
      ),
      if (profile.picAssignmentType != null)
        _DetailData(
          'Responsibility',
          profile.assignmentLabel,
          Icons.assignment_turned_in_outlined,
        ),
    ];
    return GacContentPanel(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      borderRadius: 21,
      shadowBlurRadius: 20,
      shadowOffset: const Offset(0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _DetailRow(data: details[index]),
            if (index != details.length - 1)
              const Divider(height: 1, color: GacColors.cardBorder),
          ],
        ],
      ),
    );
  }
}

class _DetailData {
  const _DetailData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.data});
  final _DetailData data;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 72),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x242979FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 18, color: GacColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label.toUpperCase(),
                  style: const TextStyle(
                    color: GacColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: GacColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
    super.key,
  });
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GacContentPanel(
    borderRadius: 18,
    shadowBlurRadius: 18,
    shadowOffset: const Offset(0, 6),
    clipBehavior: Clip.antiAlias,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x242979FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: GacColors.cyan),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          color: GacColors.textSecondary,
                          fontSize: 9,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: GacColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile, required this.repository});
  final AuthenticatedUser profile;
  final ProfileRepository repository;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await widget.repository.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
      );
      if (mounted) Navigator.of(context).pop(profile);
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Edit information',
    subtitle: 'Your branch and task responsibility are managed by Gateway.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('profile-name-field'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your full name.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('profile-email-field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Enter your email address.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: GacColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-profile-information'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GacColors.white,
                    ),
                  )
                : const Text('Save changes'),
          ),
        ],
      ),
    ),
  );
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.repository});
  final ProfileRepository repository;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _saving = false;
  bool _showCurrent = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.changePassword(
        currentPassword: _currentController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Change password',
    subtitle: 'Use at least 8 characters and keep it private.',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('current-password-field'),
            controller: _currentController,
            obscureText: !_showCurrent,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Current password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showCurrent = !_showCurrent),
                icon: Icon(
                  _showCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Enter your current password.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('new-password-field'),
            controller: _passwordController,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.password_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value?.length ?? 0) < 8 ? 'Use at least 8 characters.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('confirm-password-field'),
            controller: _confirmationController,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.password_rounded),
            ),
            validator: (value) => value != _passwordController.text
                ? 'The passwords do not match.'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: GacColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-new-password'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GacColors.white,
                    ),
                  )
                : const Text('Update password'),
          ),
        ],
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Material(
      color: GacColors.cardSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF244B67),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: GacColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.35,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: GacColors.textSecondary,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _pressed ? 0.994 : 1,
    duration: const Duration(milliseconds: 90),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3E2979FF),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: _pressed ? GacColors.primaryPressed : GacColors.primary,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: const SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 20, color: GacColors.white),
                SizedBox(width: 9),
                Text(
                  'SIGN OUT',
                  style: TextStyle(
                    color: GacColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
