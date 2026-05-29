import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../supabase_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _isAnyFocused = false;

  void _updateFocus() {
    setState(() {
      _isAnyFocused = _nameFocusNode.hasFocus || _emailFocusNode.hasFocus;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _nameFocusNode.addListener(_updateFocus);
    _emailFocusNode.addListener(_updateFocus);
  }

  void _loadCurrentUser() {
    final user = supabase.auth.currentUser;
    final meta = user?.userMetadata;
    final name = (meta?['full_name'] as String?)?.trim() ??
        (meta?['name'] as String?)?.trim() ??
        '';
    _nameController.text = name;
    _emailController.text = user?.email ?? '';

    _nameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
  }

  void _onChanged() {
    final user = supabase.auth.currentUser;
    final meta = user?.userMetadata;
    final originalName = (meta?['full_name'] as String?)?.trim() ??
        (meta?['name'] as String?)?.trim() ??
        '';
    final originalEmail = user?.email ?? '';
    final changed = _nameController.text.trim() != originalName ||
        _emailController.text.trim() != originalEmail;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final user = supabase.auth.currentUser;

    setState(() => _isLoading = true);

    try {
      UserAttributes attrs = UserAttributes(
        data: {'full_name': name},
      );

      if (email != user?.email) {
        attrs = UserAttributes(
          email: email,
          data: {'full_name': name},
        );
      }

      await supabase.auth.updateUser(attrs);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                email != user?.email
                    ? 'Profile updated! Check your email to confirm new address.'
                    : 'Profile updated successfully!',
              ),
            ],
          ),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.message)),
              ],
            ),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Something went wrong: $e')),
              ],
            ),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          // ── Green Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brandGreenGradientStart,
                  AppColors.brandGreenGradientEnd,
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back button
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                          ),
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Title & Avatar
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white.withValues(alpha: 0.35)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.userCog,
                              size: 30,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update your personal information',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form Content ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    const Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedForeground,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAnyFocused
                              ? AppColors.brandGreen.withValues(alpha: 0.4)
                              : AppColors.border.withValues(alpha: 0.4),
                          width: _isAnyFocused ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isAnyFocused
                                ? AppColors.brandGreen.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.02),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name field
                          const _FieldLabel(label: 'Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            enabled: !_isLoading,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Your full name',
                              prefixIcon: _PrefixIcon(icon: LucideIcons.user),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          const _FieldLabel(label: 'Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'your@email.com',
                              prefixIcon: _PrefixIcon(icon: LucideIcons.mail),
                              prefixIconConstraints:
                                  BoxConstraints(minWidth: 0, minHeight: 0),
                              helperText:
                                  'Changing email will require confirmation',
                              helperStyle: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.infoBlueBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.infoBlue.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info,
                              size: 16, color: AppColors.infoBlue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your name is displayed across the app. Email changes require re-verification.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.infoBlue,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_hasChanges)
                            ? null
                            : _handleSave,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor: AppColors.border.withValues(alpha: 0.3),
                          disabledForegroundColor: AppColors.mutedForeground,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.save,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared local widgets ─────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    );
  }
}

class _PrefixIcon extends StatelessWidget {
  final IconData icon;
  const _PrefixIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Icon(icon, size: 16, color: AppColors.mutedForeground),
    );
  }
}
