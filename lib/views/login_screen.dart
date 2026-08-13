import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_images.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import 'forgot_password_screen.dart';
import 'main_navigation_screen.dart';
import 'register_screen.dart';
import 'widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    setState(() => _loading = true);
    final pengguna = await DBHelper().loginUser(email, password);
    setState(() => _loading = false);

    if (!mounted) return;

    if (pengguna != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login gagal! Email atau Password salah.'),
        ),
      );
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
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Selamat Datang ',
                                  style: AppTextStyles.heading1,
                                ),
                                const TextSpan(text: '👋'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
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
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
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
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text('Masuk', style: AppTextStyles.button),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.border),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'Atau lanjutkan dengan',
                                  style: AppTextStyles.subtitleSmall,
                                ),
                              ),
                              const Expanded(
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Google Sign-In belum tersedia',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 28,
                                color: Colors.redAccent,
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
                              Text(
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
                                child: Text(
                                  'Daftar',
                                  style: AppTextStyles.linkBold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 12),
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
