import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../supabase_client.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'scan_screen.dart';
import 'meals_screen.dart';
import 'notifications_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _mealsRefreshKey = 0;
  int _inventoryRefreshKey = 0;
  int _homeRefreshKey = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _runNotificationCheck();
  }

  // ── Generate expiry notifications then refresh badge count ───────────────
  Future<void> _runNotificationCheck() async {
    await NotificationService.instance.checkAndNotify();
    await _refreshUnreadCount();

    // Listen for real-time notification changes to keep the badge updated
    supabase
        .channel('public:notifications')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              _refreshUnreadCount();
            })
        .subscribe();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final result = await supabase
          .from('notifications')
          .select('id')
          .eq('read', false)
          .eq('user_id', userId);

      if (mounted) {
        setState(() => _unreadCount = (result as List).length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    supabase.channel('public:notifications').unsubscribe();
    super.dispose();
  }

  void _goToInventory() => setState(() => _currentIndex = 1);
  void _goToScan()      => setState(() => _currentIndex = 2);
  void _goToMeals()     => setState(() {
    _currentIndex = 3;
    _mealsRefreshKey++;
  });

  void _refreshData() => setState(() {
    _homeRefreshKey++;
    _inventoryRefreshKey++;
  });

  // Called when user taps the Alerts tab — clear badge after short delay
  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 4) {
      // Refresh unread count after user views notifications
      Future.delayed(const Duration(seconds: 2), _refreshUnreadCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    final screens = [
      HomeScreen(key: ValueKey(_homeRefreshKey), onGoToInventory: _goToInventory, onGoToScan: _goToScan, onGoToMeals: _goToMeals),
      InventoryScreen(key: ValueKey(_inventoryRefreshKey)),
      const ScanScreen(),
      MealsScreen(key: ValueKey(_mealsRefreshKey), onItemsConsumed: _refreshData),
      const NotificationsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: List.generate(screens.length, (i) {
          return Offstage(
            offstage: _currentIndex != i,
            child: screens[i],
          );
        }),
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        unreadCount: _unreadCount,
      ),
    );
  }
}

// ── Nav item data ──────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

const _kNavItems = [
  _NavItem(icon: LucideIcons.home,     label: 'Home'),
  _NavItem(icon: LucideIcons.package,  label: 'Inventory'),
  _NavItem(icon: LucideIcons.scan,     label: 'Scan'),
  _NavItem(icon: LucideIcons.utensils, label: 'Meals'),
  _NavItem(icon: LucideIcons.bell,     label: 'Alerts'),
];

// ── Premium bottom nav bar ─────────────────────────────────────────────────
class _PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  const _PremiumBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_kNavItems.length, (index) {
              final item = _kNavItems[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItemWidget(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    badgeCount: index == 4 ? unreadCount : 0,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Individual nav item with animated pill ─────────────────────────────────
class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? Colors.white : const Color(0xFF9CA3AF);
    final labelColor = isSelected ? AppColors.brandGreen : const Color(0xFF9CA3AF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pill + icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: isSelected ? 48 : 36,
          height: isSelected ? 32 : 28,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _buildIcon(iconColor),
          ),
        ),
        const SizedBox(height: 4),
        // Label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: labelColor,
            height: 1.0,
          ),
          child: Text(label),
        ),
      ],
    );
  }

  Widget _buildIcon(Color iconColor) {
    Widget iconWidget = Icon(icon, size: 22, color: iconColor);

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.urgentRed,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}