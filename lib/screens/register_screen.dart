import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../supabase_client.dart';
import '../widgets/fade_in_slide.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isAnyFocused = false;

  void _updateFocus() {
    setState(() {
      _isAnyFocused = _nameFocusNode.hasFocus ||
          _emailFocusNode.hasFocus ||
          _passwordFocusNode.hasFocus ||
          _confirmPasswordFocusNode.hasFocus;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_updateFocus);
    _emailFocusNode.addListener(_updateFocus);
    _passwordFocusNode.addListener(_updateFocus);
    _confirmPasswordFocusNode.addListener(_updateFocus);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! Please check your email or log in.'),
            backgroundColor: AppColors.brandGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
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
            content: const Text('Something went wrong. Please try again.'),
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
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.mintBg,
                  Colors.white,
                ],
                stops: [0.0, 0.6],
              ),
            ),
          ),

          // Organic decorative shapes
          Positioned(
            left: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: 120,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: 100,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.brandGreen.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Sprout icons in corners (low opacity)
          Positioned(
            left: 24,
            top: 50,
            child: Icon(
              LucideIcons.sprout,
              size: 24,
              color: AppColors.brandGreen.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 50,
            child: Icon(
              LucideIcons.leaf,
              size: 24,
              color: AppColors.brandGreen.withValues(alpha: 0.08),
            ),
          ),

          // Core content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo Header ──────────────────────────────────────────
                      FadeInSlide(
                        delay: Duration.zero,
                        child: Column(
                          children: [
                            _ShimmerIcon(isLoading: _isLoading),
                            const SizedBox(height: 18),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.foreground,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Join ZeroWaste & start saving food',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Card Form ────────────────────────────────────────────
                      FadeInSlide(
                        delay: const Duration(milliseconds: 150),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isAnyFocused
                                  ? AppColors.brandGreen.withValues(alpha: 0.4)
                                  : AppColors.border.withValues(alpha: 0.4),
                              width: _isAnyFocused ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isAnyFocused
                                    ? AppColors.brandGreen.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name
                              _buildLabel('Full Name'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                enabled: !_isLoading,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: 'John Doe',
                                  prefixIcon: _buildPrefixIcon(LucideIcons.user),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Email
                              _buildLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: 'your.email@example.com',
                                  prefixIcon: _buildPrefixIcon(LucideIcons.mail),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: !_showPassword,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: '••••••••••',
                                  prefixIcon: _buildPrefixIcon(LucideIcons.lock),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  suffixIcon: _buildPasswordToggle(
                                    _showPassword,
                                    () => setState(() => _showPassword = !_showPassword),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              _buildLabel('Confirm Password'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: !_showConfirmPassword,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: '••••••••••',
                                  prefixIcon: _buildPrefixIcon(LucideIcons.lock),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  suffixIcon: _buildPasswordToggle(
                                    _showConfirmPassword,
                                    () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Create Account button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandGreen,
                                    disabledBackgroundColor: AppColors.mintBg,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: _isLoading ? 0 : 2,
                                    shadowColor: AppColors.brandGreen.withValues(alpha: 0.3),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.brandGreen,
                                          ),
                                        )
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Link to Login ────────────────────────────────────────
                      FadeInSlide(
                        delay: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground, fontWeight: FontWeight.w500),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Icon(icon, size: 16, color: AppColors.mutedForeground),
    );
  }

  Widget _buildPasswordToggle(bool visible, VoidCallback onTap) {
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

class _ShimmerIcon extends StatefulWidget {
  final bool isLoading;
  const _ShimmerIcon({required this.isLoading});

  @override
  State<_ShimmerIcon> createState() => _ShimmerIconState();
}

class _ShimmerIconState extends State<_ShimmerIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ShimmerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandGreenGradientStart,
                Color.lerp(AppColors.brandGreenGradientEnd, AppColors.mint, val) ?? AppColors.brandGreenGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandGreen.withValues(alpha: 0.2 + (val * 0.1)),
                blurRadius: 12 + (val * 8),
                offset: Offset(0, 4 + (val * 4)),
              ),
            ],
          ),
          child: Transform.scale(
            scale: widget.isLoading ? 1.0 + (val * 0.06) : 1.0,
            child: const Icon(LucideIcons.sprout, size: 38, color: Colors.white),
          ),
        );
      },
    );
  }
}