import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_images.dart';
import '../constants/app_typography.dart';
import 'main_navigation_screen.dart';

class OnboardingItem {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingItem({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  int _currentPage = 0;

  static const List<OnboardingItem> _items = [
    OnboardingItem(
      image: AppImages.onboarding1,
      eyebrow: 'FOOD MANAGEMENT',
      title: 'Kelola Food\nInventory',
      description:
          'Pantau stok makanan, tanggal kadaluwarsa, dan dapatkan pengingat sebelum makanan terbuang sia-sia',
      icon: Icons.inventory_2_outlined,
    ),
    OnboardingItem(
      image: AppImages.onboarding2,
      eyebrow: 'HEALTH MONITORING',
      title: 'Pilih Makanan\nLebih Sehat',
      description:
          'Lacak asupan nutrisi harianmu dan buat pilihan makanan yang lebih baik untuk tubuhmu',
      icon: Icons.monitor_heart_outlined,
    ),
    OnboardingItem(
      image: AppImages.onboarding3,
      eyebrow: 'YOUR IMPACT',
      title: 'Kurangi Sampah\nMakanan',
      description:
          'Bersama FoodCura, kurangi limbah makanan rumah tangga dan dukung lingkungan yang lebih berkelanjutan',
      icon: Icons.eco_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _onNextPressed() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // PageView Slides
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Column(
                children: [
                  // Hero Image Header (52% height)
                  SizedBox(
                    height: screenHeight * 0.52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background Hero Image with Rounded Bottom Corners
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.asset(
                              item.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),

                        // Subtle Gradient Overlay on top for Skip Button readability
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Overlapping Floating Feature Icon Badge
                        Positioned(
                          bottom: -36,
                          left: 32,
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _bounceAnimation.value),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Area below Hero
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 32,
                        right: 32,
                        top: 56,
                        bottom: 100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Eyebrow Tag
                          Text(
                            item.eyebrow,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.primary,
                              fontFamily: AppTextStyles.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Main Title
                          Text(
                            item.title,
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            item.description,
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Navigation (Skip Button)
          Positioned(
            top: mediaQuery.padding.top + 16,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _navigateToLogin,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Controls Bar (Pagination Dots & Action Button)
          Positioned(
            left: 24,
            right: 24,
            bottom: mediaQuery.padding.bottom + 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pagination Dots Indicator
                Row(
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next / Get Started Button
                ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPage == _items.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
