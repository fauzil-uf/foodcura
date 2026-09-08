import 'dart:async';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/profile_controller.dart';
import '../../../models/user_model.dart';
import '../../widgets/app_snack_bar.dart';

// Modal lembar bawah untuk mengganti kata sandi akun pengguna.
class ChangePasswordModal extends StatefulWidget {
  final UserModelSQL? user;
  final ProfileController controller;

  const ChangePasswordModal({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  int _failedAttempts = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _startLockout(int seconds) {
    setState(() {
      _lockoutSeconds = seconds;
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_lockoutSeconds > 1) {
          _lockoutSeconds--;
        } else {
          _lockoutSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleChangePassword() async {
    if (_lockoutSeconds > 0) {
      AppSnackBar.showError(
        context,
        'Terlalu banyak percobaan gagal. Silakan tunggu $_lockoutSeconds detik.',
      );
      return;
    }

    final oldPass = _oldPassCtrl.text;
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      AppSnackBar.showError(context, 'Semua kolom kata sandi wajib diisi!');
      return;
    }

    if (newPass.length < 8) {
      AppSnackBar.showError(context, 'Kata sandi baru minimal 8 karakter!');
      return;
    }

    if (newPass == oldPass) {
      AppSnackBar.showError(
        context,
        'Kata sandi baru tidak boleh sama dengan kata sandi lama!',
      );
      return;
    }

    if (newPass != confirmPass) {
      AppSnackBar.showError(
        context,
        'Konfirmasi kata sandi baru tidak cocok!',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.changePassword(
      oldPassword: oldPass,
      newPassword: newPass,
    );

    if (!mounted) return;

    if (success) {
      _failedAttempts = 0;
      Navigator.pop(context, true);
      AppSnackBar.showSuccess(context, 'Kata sandi berhasil diperbarui!');
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startLockout(30);
        setState(() => _isSubmitting = false);
        AppSnackBar.showError(
          context,
          'Terlalu banyak percobaan gagal. Akses ubah kata sandi dikunci selama 30 detik demi keamanan.',
        );
        return;
      }

      setState(() => _isSubmitting = false);
      final remaining = 5 - _failedAttempts;
      final errorMsg =
          widget.controller.errorMessage ?? 'Gagal mengubah kata sandi.';
      AppSnackBar.showError(
        context,
        '$errorMsg (Sisa percobaan: $remaining)',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogle = widget.user?.isGoogleAccount ?? false;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isGoogle
                          ? const Color(0xFFE8F0FE)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isGoogle
                          ? Icons.security_rounded
                          : Icons.lock_reset_rounded,
                      color: isGoogle
                          ? const Color(0xFF1976D2)
                          : const Color(0xFFF57F17),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isGoogle ? 'Keamanan Akun' : 'Ganti Kata Sandi',
                    style: AppTextStyles.headlineMd,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isGoogle
                    ? 'Informasi pengelolaan keamanan akun Google Anda.'
                    : 'Perbarui kata sandi akun Anda untuk meningkatkan keamanan.',
                style: AppTextStyles.subtitleSmall,
              ),
              const SizedBox(height: 20),

              if (isGoogle) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F0FE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              size: 18,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Akun Terhubung dengan Google',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: const Color(0xFF1A73E8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Akun Anda masuk menggunakan autentikasi Google Sign-In. Kata sandi akun Anda dikelola secara terpusat oleh Google, sehingga pembaruan kata sandi dapat dilakukan melalui Pengaturan Akun Google Anda.',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 12.5,
                          height: 1.5,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Mengerti',
                      style: AppTextStyles.button.copyWith(fontSize: 15),
                    ),
                  ),
                ),
              ] else ...[
                _buildPasswordField(
                  controller: _oldPassCtrl,
                  label: 'Kata Sandi Saat Ini',
                  hint: 'Masukkan kata sandi lama',
                  obscure: _obscureOld,
                  onToggleObscure: () {
                    setState(() => _obscureOld = !_obscureOld);
                  },
                ),
                const SizedBox(height: 14),
                _buildPasswordField(
                  controller: _newPassCtrl,
                  label: 'Kata Sandi Baru',
                  hint: 'Minimal 8 karakter',
                  obscure: _obscureNew,
                  onToggleObscure: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                ),
                const SizedBox(height: 14),
                _buildPasswordField(
                  controller: _confirmPassCtrl,
                  label: 'Konfirmasi Kata Sandi Baru',
                  hint: 'Ulangi kata sandi baru',
                  obscure: _obscureConfirm,
                  onToggleObscure: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gunakan minimal 8 karakter dengan kombinasi huruf dan angka.',
                          style: AppTextStyles.subtitleSmall.copyWith(
                            fontSize: 11.5,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (_lockoutSeconds > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          color: AppColors.urgent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Akses terkunci sementara. Coba lagi dalam $_lockoutSeconds detik.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.urgent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lockoutSeconds > 0
                          ? AppColors.textGraySoft
                          : AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (_isSubmitting || _lockoutSeconds > 0)
                        ? null
                        : _handleChangePassword,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _lockoutSeconds > 0
                                ? 'Terkunci ($_lockoutSeconds dtk)'
                                : 'Perbarui Kata Sandi',
                            style: AppTextStyles.button.copyWith(fontSize: 15),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.subtitleSmall,
        hintStyle: AppTextStyles.subtitleSmall.copyWith(
          color: AppColors.textGraySoft,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textGraySoft,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
