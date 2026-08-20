import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';
import '../../services/preference_handler.dart';
import '../auth/login_screen.dart';
import '../navigation/main_navigation_screen.dart';

/// Layar pembuka (Splash Screen) dengan animasi logo elastis, efek shimmer teks, dan pengecekan sesi login pengguna.
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
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _shimmerAnimation;

  /// Menginisialisasi controller animasi elastis logo, pergeseran teks, dan pengulangan kilau shimmer.
  @override
  void initState() {
    super.initState();

    // 1. Animasi Logo Pop-in: Menggunakan kurva elastis agar logo membal (bouncy entrance) dan memudar masuk secara mulus.
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 2. Animasi Teks Meluncur: Menggeser teks 'FoodCura' dari sisi kiri (Offset -0.45) ke posisi tengah (Offset.zero) dengan kurva easeOutCubic.
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(-0.45, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // 3. Efek Kilau Shimmer: Menggerakkan gradasi warna cahaya putih-mint melintasi teks secara berulang (repeat) dari kiri ke kanan (-1.0 ke 2.0).
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _startAnimations();
  }

  /// Menjalankan koreografi animasi bertingkat (Staggered Animation):
  /// Logo muncul terlebih dahulu -> Teks meluncur masuk -> Tahan sejenak agar pengguna dapat menikmati visual -> Pindah rute.
  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) _navigateNext();
  }

  /// Mengecek sesi login pengguna di SharedPreferences untuk menentukan rute navigasi selanjutnya.
  Future<void> _navigateNext() async {
    // Periksa apakah token sesi login masih aktif untuk menghindari login ulang yang tidak perlu.
    final bool isLoggedIn = PreferenceHandler.isLogin;

    if (!mounted) return;

    final Widget destination = isLoggedIn
        ? const MainNavigationScreen()
        : const LoginScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Melepas seluruh AnimationController dari memori untuk mencegah kebocoran memori (memory leak).
  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Membangun kanvas latar belakang layar penuh dengan gradasi hijau hutan dan lingkaran ambient.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepForest,
              AppColors.primary,
              AppColors.primaryContainer,
              AppColors.splashAccent,
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Lingkaran ambient semi-transparan yang ditempatkan secara diagonal untuk memberi efek pencahayaan atmosferik.
            Positioned(
              top: -80,
              right: -60,
              child: _buildDecorativeCircle(200, 0.06),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _buildDecorativeCircle(250, 0.05),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: -40,
              child: _buildDecorativeCircle(120, 0.04),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.3,
              right: -30,
              child: _buildDecorativeCircle(100, 0.04),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo aplikasi dengan animasi pembesaran (Scale) dan pemudaran (Opacity) simultan.
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
                    // Container bertindak sebagai wadah bingkai untuk bayangan melengkung 32px.
                    // ClipRRect bertindak sebagai gunting presisi untuk memotong 4 sudut tajam gambar logo agar sejajar 32px dengan bayangannya.
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(AppImages.logo, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Teks nama aplikasi dengan transisi meluncur dari kiri dan efek masker kilau (ShaderMask).
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          // ShaderMask memotong LinearGradient dinamis di atas teks:
                          // Nilai stops dikalkulasikan dengan offset ±0.3 lalu di-clamp (0.0 - 1.0) untuk menciptakan efek kilau cahaya mengalir.
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: const [
                                  Colors.white,
                                  AppColors.mintAccent,
                                  Colors.white,
                                ],
                                stops: [
                                  (_shimmerAnimation.value - 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  _shimmerAnimation.value.clamp(0.0, 1.0),
                                  (_shimmerAnimation.value + 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                ],
                              ).createShader(bounds);
                            },
                            child: child!,
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Food',
                                style: AppTextStyles.logo.copyWith(
                                  fontSize: 34,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: 'Cura',
                                style: AppTextStyles.logo.copyWith(
                                  fontSize: 34,
                                  color: AppColors.mintAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun elemen lingkaran dekoratif latar belakang dengan opasitas rendah untuk efek atmosferik.
  Widget _buildDecorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
