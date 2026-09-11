import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../services/app_notifiers.dart';
import '../dashboard/dashboard_screen.dart';
import '../food_info/food_info_screen.dart';
import '../food_tracker/food_tracker_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';

import '../../services/app_update_service.dart';
import '../../services/reminder_service.dart';

/// Kerangka navigasi utama (bottom navigation bar)
class MainNavigationScreen extends StatefulWidget {
  final int initialTab;

  const MainNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  late final Set<int> _loadedTabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialTab;
    _loadedTabs = {_currentIndex};
    _syncNotificationState();

    // Periksa apakah versi ini baru bagi pengguna (In-App Update Notification)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkAndShowWhatsNew(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationState();
    }
  }

  Future<void> _syncNotificationState() async {
    final reminderService = ReminderService();
    await reminderService.checkExpiryAndCreateNotifications();
    await reminderService.checkMealRemindersAndCreateNotifications();
    await reminderService.syncMealAlarms();
    await reminderService.syncPantryExpiryAlarms();
    await NotificationNotifier.instance.refresh();
  }

  /// Tangani perpindahan tab aktif dan sinkronkan refresh badge notifikasi
  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _loadedTabs.add(index);
      });
      NotificationNotifier.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _loadedTabs.contains(0)
          ? DashboardScreen(
              onNavigateToTracker: () => _onTabTapped(1),
              onNavigateToPantry: () => _onTabTapped(2),
            )
          : const SizedBox.shrink(),
      _loadedTabs.contains(1)
          ? const FoodTrackerScreen()
          : const SizedBox.shrink(),
      _loadedTabs.contains(2) ? const PantryScreen() : const SizedBox.shrink(),
      _loadedTabs.contains(3)
          ? const FoodInfoScreen()
          : const SizedBox.shrink(),
      _loadedTabs.contains(4) ? const ProfileScreen() : const SizedBox.shrink(),
    ];

    const double bottomPosition = 14.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: screens),

          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPosition,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepForest.withValues(alpha: 0.12),
                    blurRadius: 26,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    0,
                    Icons.home_outlined,
                    Icons.home_rounded,
                    'Home',
                  ),
                  _buildNavItem(
                    1,
                    Icons.analytics_outlined,
                    Icons.analytics_rounded,
                    'Tracker',
                  ),
                  _buildNavItem(
                    2,
                    Icons.inventory_2_outlined,
                    Icons.inventory_2_rounded,
                    'Pantry',
                  ),
                  _buildNavItem(
                    3,
                    Icons.info_outlined,
                    Icons.info_rounded,
                    'FoodInfo',
                  ),
                  _buildNavItem(
                    4,
                    Icons.person_outlined,
                    Icons.person_rounded,
                    'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData iconInactive,
    IconData iconActive,
    String label,
  ) {
    final isActive = _currentIndex == index;

    if (isActive) {
      return GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconActive, size: 22, color: Colors.white),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.navLabelActive),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconInactive, size: 22, color: AppColors.textGray),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.navLabel),
          ],
        ),
      ),
    );
  }
}
