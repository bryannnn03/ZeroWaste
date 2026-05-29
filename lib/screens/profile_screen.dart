import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_card_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _expiryNotifications = true;
  bool _loading = true;
  String _userName = '';
  String _userEmail = '';
  int _itemsTracked = 0;
  int _wasteReduced = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      final meta = user?.userMetadata;
      final name = (meta?['full_name'] as String?)?.trim() ??
          (meta?['name'] as String?)?.trim() ??
          user?.email?.split('@').first ??
          'User';
      final email = user?.email ?? '';

      final countResponse = await supabase
          .from('inventory')
          .select('id')
          .eq('status', 'active');
      final count = (countResponse as List).length;

      final wasteResponse = await supabase
          .from('inventory')
          .select('status, quantity')
          .neq('status', 'active');
          
      int consumed = 0;
      int wasted = 0;
      
      for (var row in wasteResponse as List) {
        final status = row['status'] as String?;
        final qty = (row['quantity'] as int?) ?? 1;
        if (status == 'consumed') consumed += qty;
        if (status == 'wasted') wasted += qty;
      }
      
      int wastePercent = 0;
      if (consumed + wasted > 0) {
        wastePercent = ((consumed / (consumed + wasted)) * 100).round();
      } else {
        wastePercent = 100;
      }

      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = email;
          _itemsTracked = count;
          _wasteReduced = wastePercent;
          _expiryNotifications = meta?['expiry_notifications'] as bool? ?? true;
          _loading = false;
        });
      }
    } catch (_) {
      final user = supabase.auth.currentUser;
      final meta = user?.userMetadata;
      if (mounted) {
        setState(() {
          _userName = (meta?['full_name'] as String?)?.trim() ??
              user?.email?.split('@').first ?? 'User';
          _userEmail = user?.email ?? '';
          _expiryNotifications = meta?['expiry_notifications'] as bool? ?? true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header with Rounded Bottom
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (Navigator.canPop(context))
                        Positioned(
                          left: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                              ),
                              child: const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      FadeInSlide(
                        delay: Duration.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                width: 82, height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                                  ],
                                ),
                                child: const Icon(LucideIcons.user, size: 36, color: AppColors.brandGreen),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _loading
                                ? Container(
                                    width: 120,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  )
                                : Text(_userName,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                            const SizedBox(height: 4),
                            _loading
                                ? Container(
                                    width: 160,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  )
                                : Text(_userEmail,
                                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats Card (overlapping)
            FadeInSlide(
              delay: const Duration(milliseconds: 150),
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedCardWrapper(
                    borderRadius: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.brandGreen, AppColors.mint],
                                ),
                              ),
                            ),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40, height: 40,
                                            decoration: const BoxDecoration(color: AppColors.infoBlueBg, shape: BoxShape.circle),
                                            child: const Icon(LucideIcons.package, size: 18, color: AppColors.infoBlue),
                                          ),
                                          const SizedBox(height: 8),
                                          _loading
                                              ? Container(
                                                  width: 40, height: 22,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                )
                                              : TweenAnimationBuilder<int>(
                                                  tween: IntTween(begin: 0, end: _itemsTracked),
                                                  duration: const Duration(milliseconds: 800),
                                                  curve: Curves.easeOutCubic,
                                                  builder: (context, value, child) => Text(
                                                    '$value',
                                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.foreground),
                                                  ),
                                                ),
                                          const SizedBox(height: 2),
                                          const Text('Items Tracked',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(width: 1, color: AppColors.border.withValues(alpha: 0.3)),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 40, height: 40,
                                            decoration: const BoxDecoration(color: AppColors.mintBg, shape: BoxShape.circle),
                                            child: const Icon(LucideIcons.trendingUp, size: 18, color: AppColors.brandGreen),
                                          ),
                                          const SizedBox(height: 8),
                                          _loading
                                              ? Container(
                                                  width: 40, height: 22,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                )
                                              : TweenAnimationBuilder<int>(
                                                  tween: IntTween(begin: 0, end: _wasteReduced),
                                                  duration: const Duration(milliseconds: 800),
                                                  curve: Curves.easeOutCubic,
                                                  builder: (context, value, child) => Text(
                                                    '$value%',
                                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.brandGreen),
                                                  ),
                                                ),
                                          const SizedBox(height: 2),
                                          const Text('Waste Reduced',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Settings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Settings Section
                  const FadeInSlide(
                    delay: Duration(milliseconds: 200),
                    child: Text('ACCOUNT SETTINGS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mutedForeground, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 250),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.white,
                          child: Column(
                            children: [
                              _SettingsRow(
                                icon: LucideIcons.user,
                                iconBg: AppColors.infoBlueBg,
                                iconColor: AppColors.infoBlue,
                                title: 'Edit Profile',
                                subtitle: 'Update your information',
                                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                              ),
                              Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                              _SettingsRow(
                                icon: LucideIcons.lock,
                                iconBg: const Color(0xFFF3E8FF),
                                iconColor: const Color(0xFF8B5CF6),
                                title: 'Change Password',
                                subtitle: 'Update your password',
                                onTap: () => Navigator.pushNamed(context, '/change-password'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preferences Section
                  const FadeInSlide(
                    delay: Duration(milliseconds: 300),
                    child: Text('PREFERENCES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mutedForeground, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 10),
                  FadeInSlide(
                    delay: const Duration(milliseconds: 350),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(color: AppColors.soonOrangeBg, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.bell, size: 18, color: AppColors.soonOrange),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expiry Notifications',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                                SizedBox(height: 2),
                                Text('Get alerts for expiring items',
                                    style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                            Switch(
                            value: _expiryNotifications,
                            onChanged: (v) async {
                              setState(() => _expiryNotifications = v);
                              try {
                                await supabase.auth.updateUser(
                                  UserAttributes(data: {'expiry_notifications': v})
                                );
                              } catch (_) {
                                if (mounted) setState(() => _expiryNotifications = !v);
                              }
                            },
                            activeThumbColor: AppColors.brandGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logout Button
                  FadeInSlide(
                    delay: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(LucideIcons.logOut, size: 18, color: AppColors.urgentRed),
                        label: const Text('Logout',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.urgentRed)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.urgentRedBg.withValues(alpha: 0.4),
                          foregroundColor: AppColors.urgentRed,
                          side: BorderSide(color: AppColors.urgentRed.withValues(alpha: 0.2), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Footer
                  FadeInSlide(
                    delay: const Duration(milliseconds: 450),
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.sprout, size: 14, color: AppColors.brandGreen.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              const Text('ZeroWaste v1.0.0',
                                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('Making a difference, one meal at a time',
                              style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.foreground)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}
