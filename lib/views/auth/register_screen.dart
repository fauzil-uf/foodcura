import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';
import '../../controllers/auth_controller.dart';
import '../navigation/main_navigation_screen.dart';
import '../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final success = await _authController.register(
      name: name,
      email: email,
      password: pass,
      confirmPassword: confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      await _authController.login(email, pass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selamat datang, $name!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else if (_authController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_authController.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.bgRegister),
              fit: BoxFit.cover,
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
                          Image.asset(AppImages.logo, width: 110),
                          const SizedBox(height: 6),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(26, 28, 26, 27),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF48412B,
                                  ).withValues(alpha: 0.12),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Daftar Akun Baru',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.heading2,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Mulai langkah sehatmu dan kurangi\nfood waste hari ini.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.subtitleSmall,
                                ),
                                const SizedBox(height: 18),
                                AppTextField(
                                  controller: nameController,
                                  hint: 'Nama Lengkap',
                                  icon: Icons.person_outline_rounded,
                                  fillColor: AppColors.inputFillSoft.withValues(
                                    alpha: 0.48,
                                  ),
                                  height: 51,
                                  radius: 15,
                                  textStyle: AppTextStyles.inputTextSmall,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: emailController,
                                  hint: 'Email',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  fillColor: AppColors.inputFillSoft.withValues(
                                    alpha: 0.48,
                                  ),
                                  height: 51,
                                  radius: 15,
                                  textStyle: AppTextStyles.inputTextSmall,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  fillColor: AppColors.inputFillSoft.withValues(
                                    alpha: 0.48,
                                  ),
                                  height: 51,
                                  radius: 15,
                                  textStyle: AppTextStyles.inputTextSmall,
                                ),
                                const SizedBox(height: 10),
                                AppTextField(
                                  controller: confirmPasswordController,
                                  hint: 'Konfirmasi Password',
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  fillColor: AppColors.inputFillSoft.withValues(
                                    alpha: 0.48,
                                  ),
                                  height: 51,
                                  radius: 15,
                                  textStyle: AppTextStyles.inputTextSmall,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 51,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryDark,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      elevation: 3,
                                    ),
                                    onPressed: _authController.isLoading
                                        ? null
                                        : _register,
                                    child: _authController.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Daftar  →',
                                            style: AppTextStyles.buttonSmall,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'atau lanjutkan dengan',
                                        style: AppTextStyles.subtitleSmall
                                            .copyWith(fontSize: 11),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 49,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.inputFillSoft
                                          .withValues(alpha: 0.46),
                                      side: const BorderSide(
                                        color: AppColors.borderSoft,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Google Sign-In belum tersedia',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: SvgPicture.asset(
                                      AppImages.icGoogle,
                                      width: 20,
                                      height: 20,
                                    ),
                                    label: Text(
                                      'Daftar dengan Google',
                                      style: AppTextStyles.inputTextSmall
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 17),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sudah punya akun? ',
                                      style: AppTextStyles.subtitleSmall,
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Text(
                                        'Masuk',
                                        style: AppTextStyles.linkBold.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
