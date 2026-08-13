import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'dashboard_screen.dart';
import 'food_tracker_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTab;

  const MainNavigationScreen({
    super.key,
    this.initialTab = 0,
  });

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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToTracker: () => _onTabTapped(1),
      ),
      const FoodTrackerScreen(),
      const _PlaceholderScreen(title: 'Pantry / Stok Dapur'),
      const _PlaceholderScreen(title: 'FoodInfo / Informasi Gizi'),
      const _PlaceholderScreen(title: 'Profil Saya'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Current Selected Screen
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2C1B).withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.analytics_outlined, Icons.analytics_rounded, 'Tracker'),
                  _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Pantry'),
                  _buildNavItem(3, Icons.info_outlined, Icons.info_rounded, 'FoodInfo'),
                  _buildNavItem(4, Icons.person_outlined, Icons.person_rounded, 'Profile'),
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
        child: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconActive, size: 22, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading2),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              '$title akan segera hadir!',
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
