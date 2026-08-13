import 'dart:ui';

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  // Color Constants
  static const Color background = Color(0xFFFAF9F3);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color deepForest = Color(0xFF0F2C1B);
  static const Color ecoGreen = Color(0xFF347A4B);
  static const Color mintTint = Color(0xFFE4F0E8);
  static const Color primaryContainer = Color(0xFF1B4D2E);
  static const Color outline = Color(0xFF717971);
  static const Color surfaceVariant = Color(0xFFE3E3DD);
  static const Color onSurfaceVariant = Color(0xFF414942);
  static const Color secondaryFixed = Color(0xFFFFDCC2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: mintTint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: secondaryFixed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur Filter to soften background shapes
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Main Form Container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: deepForest.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.eco, color: ecoGreen, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'FoodCura',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: deepForest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Smart Living, Sustainable Eating',
                      style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),

                    // Greeting
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selamat Datang 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: deepForest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Masuk untuk memantau makanan dan stok dapurmu',
                        style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Input
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: outline,
                        ),
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: outline),
                        filled: true,
                        fillColor: surfaceLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: surfaceVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    TextField(
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: outline,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: outline,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: outline),
                        filled: true,
                        fillColor: surfaceLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: surfaceVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: primaryContainer,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: surfaceVariant)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Atau lanjutkan dengan',
                            style: TextStyle(fontSize: 12, color: outline),
                          ),
                        ),
                        Expanded(child: Divider(color: surfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Auth Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: surfaceVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: Colors.blue,
                            ), // Pengganti icon google
                            label: const Text(
                              'Google',
                              style: TextStyle(color: deepForest),  
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: surfaceVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(
                              Icons.apple,
                              size: 24,
                              color: Colors.black,
                            ), // Pengganti icon apple
                            label: const Text(
                              'Apple',
                              style: TextStyle(color: deepForest),
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum memiliki akun? ',
                          style: TextStyle(color: onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              color: primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
