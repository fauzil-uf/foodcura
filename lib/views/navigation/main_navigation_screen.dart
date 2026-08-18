import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../dashboard/dashboard_screen.dart';
import '../food_info/food_info_screen.dart';
import '../food_tracker/food_tracker_screen.dart';
import '../pantry/pantry_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;

  const MainNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToTracker: () => _onTabTapped(1),
        onNavigateToPantry: () => _onTabTapped(2),
      ),
      const FoodTrackerScreen(),
      const PantryScreen(),
      const FoodInfoScreen(),
      const ProfileScreen(),
    ];

    // Posisi mengambang seimbang (tidak terlalu tinggi dan tidak terlalu mepet bawah)
    const double bottomPosition = 14.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Current Selected Screen
          IndexedStack(index: _currentIndex, children: screens),

          // Floating Glassmorphic Bottom Navigation Bar (5 tabs utama)
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
