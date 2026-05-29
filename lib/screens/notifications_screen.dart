import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../supabase_client.dart';
import '../models/notification.dart';
import '../widgets/fade_in_slide.dart';
import '../widgets/animated_card_wrapper.dart';
import '../widgets/shimmer_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with RouteAware {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();

    supabase
        .channel('public:notifications_screen')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _load();
            })
        .subscribe();
  }

  @override
  void dispose() {
    supabase.channel('public:notifications_screen').unsubscribe();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  AppNotification _rowToNotification(Map<String, dynamic> row) {
    NotificationType type;
    switch (row['type'] as String? ?? 'info') {
      case 'urgent':
        type = NotificationType.urgent;
      case 'warning':
        type = NotificationType.warning;
      default:
        type = NotificationType.info;
    }

    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now();
    final diff = DateTime.now().difference(createdAt);
    final String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      timeAgo = '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }

    return AppNotification(
      id:       row['id'].toString(),
      title:    row['title']   as String? ?? '',
      message:  row['message'] as String? ?? '',
      timeAgo:  timeAgo,
      type:     type,
      read:     row['read']    as bool? ?? false,
    );
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await supabase
          .from('notifications')
          .select('id, title, message, type, read, created_at')
          .order('created_at', ascending: false);

      final items = (response as List)
          .map((row) => _rowToNotification(row as Map<String, dynamic>))
          .toList();

      if (mounted) setState(() { _notifications = items; _loading = false; });
    } catch (e, stack) {
      debugPrint('NotificationsScreen._load error: $e\n$stack');
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> _markAllRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      for (var n in _notifications) {
        n.read = true;
      }
    });

    try {
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _load();
      }
    }
  }

  Future<void> _markRead(String id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      final notif = _notifications.firstWhere((n) => n.id == id);
      notif.read = true;
    });

    try {
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.urgentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandGreen,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const FadeInSlide(
                  delay: Duration.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.5)),
                      SizedBox(height: 2),
                      Text('Stay updated on your inventory',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Error banner ─────────────────────────────────────────────
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.urgentRedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.urgentRed.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.urgentRed),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.urgentRed))),
                        GestureDetector(
                          onTap: _load,
                          child: const Text('Retry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.urgentRed)),
                        ),
                      ],
                    ),
                  ),

                // ── Unread count card ─────────────────────────────────────
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, AppColors.surfaceGlass],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('UNREAD NOTIFICATIONS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedForeground, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: _unreadCount),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) => Text(
                                _loading ? '—' : '$value',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.foreground),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _markAllRead,
                            icon: const Icon(LucideIcons.checkCheck, size: 14, color: Colors.white),
                            label: const Text('Mark all read',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              foregroundColor: Colors.white,
                              side: BorderSide.none,
                              elevation: 2,
                              shadowColor: AppColors.brandGreen.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Loading skeleton ──────────────────────────────────────
                if (_loading)
                  ..._buildSkeleton(),

                // ── Empty state ───────────────────────────────────────────
                if (!_loading && _notifications.isEmpty && _error == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.12), width: 1.5),
                            ),
                            child: const Icon(LucideIcons.bellOff, size: 28, color: AppColors.brandGreen),
                          ),
                          const SizedBox(height: 18),
                          const Text('All caught up!', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.foreground, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('No new notifications right now.', style: TextStyle(fontSize: 13, color: AppColors.mutedForeground, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),

                // ── Notification list ─────────────────────────────────────
                if (!_loading)
                  ..._notifications.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final notif = entry.value;
                    return FadeInSlide(
                      delay: Duration(milliseconds: idx < 10 ? 150 + (idx * 50) : 0),
                      child: _buildNotifCard(notif),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSkeleton() => List.generate(
    4,
    (_) => const Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerLoading(
        width: double.infinity,
        height: 96,
        borderRadius: 16,
      ),
    ),
  );

  Widget _buildNotifCard(AppNotification notif) {
    Color borderColor;
    Widget icon;

    switch (notif.type) {
      case NotificationType.urgent:
        borderColor = AppColors.urgentRed;
        icon = Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: AppColors.urgentRedBg, shape: BoxShape.circle),
          child: const Icon(LucideIcons.alertTriangle, size: 20, color: AppColors.urgentRed),
        );
      case NotificationType.warning:
        borderColor = AppColors.soonOrange;
        icon = Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: AppColors.soonOrangeBg, shape: BoxShape.circle),
          child: const Icon(LucideIcons.clock, size: 20, color: AppColors.soonOrange),
        );
      case NotificationType.info:
        borderColor = AppColors.infoBlue;
        icon = Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: AppColors.infoBlueBg, shape: BoxShape.circle),
          child: const Icon(LucideIcons.info, size: 20, color: AppColors.infoBlue),
        );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedCardWrapper(
        onTap: () => _markRead(notif.id),
        borderRadius: 16,
        child: Opacity(
          opacity: notif.read ? 0.65 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4, 
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(notif.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: notif.read ? FontWeight.w600 : FontWeight.w700,
                                            color: AppColors.foreground,
                                          )),
                                    ),
                                    if (!notif.read)
                                      Container(
                                        width: 8, height: 8,
                                        margin: const EdgeInsets.only(top: 6, left: 8),
                                        decoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _buildMessage(notif),
                                const SizedBox(height: 8),
                                Text(notif.timeAgo,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
                              ],
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
    );
  }

  Widget _buildMessage(AppNotification notif) {
    if (notif.linkText != null) {
      final parts = notif.message.split(notif.linkText!);
      return RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, color: AppColors.mutedForeground, height: 1.5, fontWeight: FontWeight.w500),
          children: [
            if (parts.isNotEmpty) TextSpan(text: parts[0]),
            TextSpan(text: notif.linkText, style: const TextStyle(color: AppColors.brandGreen, fontWeight: FontWeight.w700)),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    }
    return Text(notif.message,
        style: const TextStyle(fontSize: 12.5, color: AppColors.mutedForeground, height: 1.5, fontWeight: FontWeight.w500));
  }
}