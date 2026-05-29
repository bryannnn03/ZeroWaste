import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../supabase_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  bool _isSendingReset = false;

  final _currentFocusNode = FocusNode();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  bool _isAnyFocused = false;

  void _updateFocus() {
    setState(() {
      _isAnyFocused = _currentFocusNode.hasFocus ||
          _newFocusNode.hasFocus ||
          _confirmFocusNode.hasFocus;
    });
  }

  // Password strength
  int _strength = 0; // 0–4

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_evaluateStrength);
    _currentFocusNode.addListener(_updateFocus);
    _newFocusNode.addListener(_updateFocus);
    _confirmFocusNode.addListener(_updateFocus);
  }

  void _evaluateStrength() {
    final p = _newPasswordController.text;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(p)) score++;
    setState(() => _strength = score);
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

  Future<void> _handleForgotPassword() async {
    final email = supabase.auth.currentUser?.email ?? '';
    if (email.isEmpty) return;

    setState(() => _isSendingReset = true);
    try {
      await supabase.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.mail, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Reset link sent to $email'),
              ),
            ],
          ),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to send reset email. Try again.'),
            ],
          ),
          backgroundColor: AppColors.urgentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final email = supabase.auth.currentUser?.email ?? '';

    setState(() => _isLoading = true);

    try {
      // Re-authenticate with current password to verify it
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update to new password
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(LucideIcons.checkCircle2, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text('Password changed successfully!'),
            ],
          ),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase().contains('invalid')
            ? 'Current password is incorrect. Please try again.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('Something went wrong. Please try again.'),
              ],
            ),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
          // ── Green Header ────────────────────────────────────────────────
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
                              LucideIcons.lock,
                              size: 30,
                              color: AppColors.brandGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep your account secure',
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

          // ── Form Content ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASSWORD',
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
                          // Current password
                          const _FieldLabel(label: 'Current Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _currentPasswordController,
                            focusNode: _currentFocusNode,
                            enabled: !_isLoading,
                            obscureText: !_showCurrent,
                            decoration: InputDecoration(
                              hintText: '••••••••••',
                              prefixIcon:
                                  const _PrefixIcon(icon: LucideIcons.lock),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIcon: _PasswordToggle(
                                visible: _showCurrent,
                                onTap: () =>
                                    setState(() => _showCurrent = !_showCurrent),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                  return 'Please enter your current password';
                              }
                              return null;
                            },
                          ),
                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _isSendingReset ? null : _handleForgotPassword,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8, right: 4),
                                child: _isSendingReset
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.brandGreen,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.brandGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            LucideIcons.mailOpen,
                                            size: 13,
                                            color: AppColors.brandGreen,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // New password
                          const _FieldLabel(label: 'New Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            focusNode: _newFocusNode,
                            enabled: !_isLoading,
                            obscureText: !_showNew,
                            decoration: InputDecoration(
                              hintText: '••••••••••',
                              prefixIcon: const _PrefixIcon(icon: LucideIcons.lock),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIcon: _PasswordToggle(
                                visible: _showNew,
                                onTap: () =>
                                    setState(() => _showNew = !_showNew),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              if (v == _currentPasswordController.text) {
                                return 'New password must differ from current';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Strength bar
                          if (_newPasswordController.text.isNotEmpty) ...[
                            _StrengthBar(strength: _strength),
                            const SizedBox(height: 16),
                          ],

                          // Confirm new password
                          const _FieldLabel(label: 'Confirm New Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocusNode,
                            enabled: !_isLoading,
                            obscureText: !_showConfirm,
                            decoration: InputDecoration(
                              hintText: '••••••••••',
                              prefixIcon: const _PrefixIcon(icon: LucideIcons.lock),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIcon: _PasswordToggle(
                                visible: _showConfirm,
                                onTap: () =>
                                    setState(() => _showConfirm = !_showConfirm),
                              ),
                              suffixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (v != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.shieldCheck,
                                  size: 16, color: Color(0xFF8B5CF6)),
                              SizedBox(width: 8),
                              Text(
                                'Password Tips',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...[
                            'At least 8 characters long',
                            'Mix uppercase & lowercase letters',
                            'Include numbers and symbols',
                          ].map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.check,
                                      size: 14, color: Color(0xFF8B5CF6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    tip,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF6D28D9),
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                  Icon(LucideIcons.shieldCheck,
                                      size: 16, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Update Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

// ── Strength bar ──────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final int strength; // 0–4
  const _StrengthBar({required this.strength});

  Color get _color {
    if (strength <= 1) return AppColors.urgentRed;
    if (strength == 2) return AppColors.soonOrange;
    if (strength == 3) return AppColors.yellowMedium;
    return AppColors.brandGreen;
  }

  String get _label {
    if (strength <= 1) return 'Weak';
    if (strength == 2) return 'Fair';
    if (strength == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? _color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: $_label',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    );
  }
}

// ── Shared local widgets ──────────────────────────────────────────────────────

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

class _PasswordToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  const _PasswordToggle({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Icon(
          visible ? LucideIcons.eyeOff : LucideIcons.eye,
          size: 16,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}
