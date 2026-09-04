import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';
import '../../controllers/auth_controller.dart';
import '../auth/login_screen.dart';
import '../navigation/main_navigation_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/reminder_service.dart';

// Layar splash pembuka dengan estetika ultra-premium, pencahayaan ambient hidup, dan kilau cahaya sinematik
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _shimmerController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _ambientPulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Logo Pop-in bermartabat (Dignified Ease-Out)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    // 2. Animasi Teks & Tagline Meluncur Masuk Vertikal Halus
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // 3. Efek Kilau Diamond & Mint Shimmer Menyeluruh (Left-to-Right Sweeping Beam)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _shimmerAnimation = Tween<double>(begin: -2.2, end: 2.2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutCubic),
    );

    // 4. Denyut Atmosferik Ambient Halus (Ethereal Breathing)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _ambientPulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOutSine),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Delegasikan inisialisasi sesi & profil sepenuhnya ke AuthController (prinsip MVC)
    final authController = AuthController();
    final authFuture = authController.loadCurrentUser();

    // 1. Jeda awal yang tenang saat kanvas ambient bernapas
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 2. Logo masuk secara anggun
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // 3. Tipografi brand & tagline meluncur naik dengan lembut
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // 4. Sapuan kilau cahaya specular menyapu megah dari kiri ke kanan secara penuh
    // Await menjamin animasi selesai 100% tuntas tanpa terpotong
    await _shimmerController.forward(from: 0.0);
    if (!mounted) return;

    // 5. Jeda harmoni visual sejenak setelah kilau cahaya rampung sempurna
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 6. Pastikan inisialisasi data user telah rampung
    await authFuture;
    final bool isLoggedIn = authController.isAuthenticated;
    final bool hasSeenOnboarding = authController.hasSeenOnboarding;
    authController.dispose();

    // Sinkronkan jadwal alarm ke Android OS setiap kali app dibuka
    if (isLoggedIn) {
      final reminderService = ReminderService();
      unawaited(reminderService.syncMealAlarms());
      unawaited(reminderService.syncPantryExpiryAlarms());
    }

    if (!mounted) return;

    final Widget destination = isLoggedIn
        ? const MainNavigationScreen()
        : (!hasSeenOnboarding ? const OnboardingScreen() : const LoginScreen());

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 550),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF091C11), // Deep Nocturnal Emerald
              Color(0xFF0E2A19),
              AppColors.deepForest,
              Color(0xFF143E24),
              Color(0xFF1A4C2D),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Orbs ambient bernapas halus (Living Atmospheric Canvas)
            AnimatedBuilder(
              animation: _ambientPulseAnimation,
              builder: (context, child) {
                final double pulse = _ambientPulseAnimation.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -60,
                      right: -50,
                      child: _buildDecorativeOrb(
                        260 * pulse,
                        AppColors.mintAccent,
                        0.09 * pulse,
                      ),
                    ),
                    Positioned(
                      bottom: -90,
                      left: -80,
                      child: _buildDecorativeOrb(
                        300 * pulse,
                        AppColors.primaryLight,
                        0.08 * pulse,
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.22,
                      left: -40,
                      child: _buildDecorativeOrb(
                        150 * pulse,
                        Colors.white,
                        0.04 * pulse,
                      ),
                    ),
                    Positioned(
                      bottom: size.height * 0.28,
                      right: -30,
                      child: _buildDecorativeOrb(
                        140 * pulse,
                        AppColors.mintAccent,
                        0.06 * pulse,
                      ),
                    ),
                  ],
                );
              },
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo aplikasi dengan Layered Halo & Wadah Beveled Glass
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Halo ambient bernapas lembut di belakang kartu logo
                        AnimatedBuilder(
                          animation: _ambientPulseAnimation,
                          builder: (context, _) {
                            final double pulse = _ambientPulseAnimation.value;
                            return Container(
                              width: 190 * pulse,
                              height: 190 * pulse,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.mintAccent.withValues(
                                      alpha: 0.32 * pulse,
                                    ),
                                    const Color(0xFF34D399).withValues(
                                      alpha: 0.12 * pulse,
                                    ),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            );
                          },
                        ),

                        // Wadah logo dengan beveled rim reflektif & dual drop-shadow
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.42),
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.28),
                              ],
                              stops: const [0.0, 0.35, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF041208).withValues(
                                  alpha: 0.65,
                                ),
                                blurRadius: 36,
                                spreadRadius: 2,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: AppColors.mintAccent.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 24,
                                spreadRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(1.5), // Fine beveled glass edge
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.5),
                              color: AppColors.deepForest,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.5),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      AppImages.logo,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  // Lapisan kilau kristal (dual-beam glass sheen) menyapu diagonal
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _shimmerAnimation,
                                      builder: (context, _) {
                                        final double val = _shimmerAnimation.value;
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment(val - 1.1, -1.0),
                                              end: Alignment(val + 1.1, 1.0),
                                              stops: const [
                                                0.0,
                                                0.35,
                                                0.48,
                                                0.52,
                                                0.65,
                                                1.0,
                                              ],
                                              colors: [
                                                Colors.white.withValues(alpha: 0.0),
                                                Colors.white.withValues(alpha: 0.08),
                                                Colors.white.withValues(alpha: 0.48),
                                                Colors.white.withValues(alpha: 0.65),
                                                Colors.white.withValues(alpha: 0.12),
                                                Colors.white.withValues(alpha: 0.0),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Teks nama aplikasi & tagline dengan transisi meluncur ke atas dan masker kilau mengalir
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tipografi Brand "FoodCura" dengan Layer Specular Shine Menyilaukan
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Layer Dasar: Warna otentik crisp (Food putih, Cura mint)
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Food',
                                      style: AppTextStyles.logo.copyWith(
                                        fontSize: 38,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Cura',
                                      style: AppTextStyles.logo.copyWith(
                                        fontSize: 38,
                                        color: AppColors.mintAccent,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Layer Kilau: Berkas cahaya diamond specular menyapu huruf secara dinamis
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _shimmerAnimation,
                                  builder: (context, _) {
                                    final double val = _shimmerAnimation.value;
                                    return ShaderMask(
                                      blendMode: BlendMode.srcIn,
                                      shaderCallback: (bounds) {
                                        return LinearGradient(
                                          begin: Alignment(val - 0.9, -0.2),
                                          end: Alignment(val + 0.9, 0.2),
                                          stops: const [
                                            0.0,
                                            0.35,
                                            0.50,
                                            0.65,
                                            1.0,
                                          ],
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.2),
                                            Colors.white, // Diamond Specular Core
                                            const Color(0xFFBAF7D0), // Iridescent Emerald Glint
                                            Colors.transparent,
                                          ],
                                        ).createShader(bounds);
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Food',
                                              style: AppTextStyles.logo.copyWith(
                                                fontSize: 38,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.6,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Cura',
                                              style: AppTextStyles.logo.copyWith(
                                                fontSize: 38,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Pill Tagline Brand Bernuansa Frosted Glass Mewah
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Permata status neon bernapas
                                AnimatedBuilder(
                                  animation: _ambientPulseAnimation,
                                  builder: (context, _) {
                                    return Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.mintAccent,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.mintAccent.withValues(
                                              alpha: 0.7 *
                                                  _ambientPulseAnimation.value,
                                            ),
                                            blurRadius:
                                                8 * _ambientPulseAnimation.value,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Nutrisi Sehat • Pantau Stok Dapur',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
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

            // Footer subtil dengan hairline progress capsule di bagian bawah layar
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hairline progress capsule yang terisi selaras dengan sapuan shimmer
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        final double progress =
                            _shimmerController.value.clamp(0.0, 1.0);
                        return Container(
                          width: 48,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 48 * progress,
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.mintAccent,
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.mintAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Nutrition & Kitchen Pantry',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        letterSpacing: 1.4,
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
    );
  }

  Widget _buildDecorativeOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}
