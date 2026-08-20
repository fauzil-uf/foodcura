import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';
import '../../controllers/auth_controller.dart';
import '../navigation/main_navigation_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../widgets/app_text_field.dart';
// import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _authController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final success = await _authController.login(
      emailController.text,
      passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (!mounted) return;

      if (!hasSeenOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } else if (_authController.errorMessage != null) {
      _showSnackBar(_authController.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.bgLogin),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: 400,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(AppImages.logo, width: 130),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Food',
                                  style: AppTextStyles.logo.copyWith(
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Cura',
                                  style: AppTextStyles.logo.copyWith(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Selamat Datang 👋',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading1,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Masuk untuk memantau kesehatan\ndan stok dapurmu.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 26),
                          AppTextField(
                            controller: emailController,
                            hint: 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            radius: 18,
                            height: 58,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            radius: 18,
                            height: 58,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showSnackBar(
                                'Fitur Lupa Password belum tersedia',
                              ),
                              child: const Text(
                                'Lupa Password?',
                                style: AppTextStyles.linkBold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 3,
                              ),
                              onPressed: _authController.isLoading
                                  ? null
                                  : _login,
                              child: _authController.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Masuk', style: AppTextStyles.button),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(color: AppColors.border),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Atau lanjutkan dengan',
                                  style: AppTextStyles.subtitleSmall,
                                ),
                              ),
                              Expanded(
                                child: Divider(color: AppColors.border),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: () => _showSnackBar('Google Sign-In belum tersedia'),
                              icon: SvgPicture.asset(
                                AppImages.icGoogle,
                                width: 22,
                                height: 22,
                              ),
                              label: Text(
                                'Lanjutkan dengan Google',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Belum memiliki akun? ',
                                style: AppTextStyles.body,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Daftar',
                                  style: AppTextStyles.linkBold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
