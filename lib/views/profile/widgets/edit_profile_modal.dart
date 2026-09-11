import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/profile_controller.dart';
import '../../../models/user_model.dart';
import '../../widgets/app_snack_bar.dart';

/// Modal lembar bawah untuk mengedit nama lengkap dan alamat email akun profil pengguna.
class EditProfileModal extends StatefulWidget {
  final UserModelSQL? user;
  final ProfileController controller;

  const EditProfileModal({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final isGoogle = widget.user?.isGoogleAccount ?? false;
    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();

    if (newName.isEmpty) {
      AppSnackBar.showError(context, 'Nama lengkap tidak boleh kosong!');
      return;
    }

    if (!isGoogle) {
      if (newEmail.isEmpty) {
        AppSnackBar.showError(context, 'Alamat email tidak boleh kosong!');
        return;
      }
      if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(newEmail)) {
        AppSnackBar.showError(context, 'Format email tidak valid!');
        return;
      }
    }

    if (newName == widget.user?.name &&
        (isGoogle || newEmail == widget.user?.email)) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.updateProfile(
      name: newName,
      email: isGoogle ? (widget.user?.email ?? newEmail) : newEmail,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSubmitting = false);
      AppSnackBar.showError(
        context,
        widget.controller.errorMessage ?? 'Gagal memperbarui profil.',
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
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Informasi Profil',
                  style: AppTextStyles.headlineMd,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Perbarui nama lengkap dan alamat email akunmu.',
              style: AppTextStyles.subtitleSmall,
            ),
            const SizedBox(height: 16),
            if (isGoogle) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD2E3FC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF1A73E8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Akun terhubung dengan Google. Email tidak dapat diubah di sini.',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          color: const Color(0xFF174EA6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _nameCtrl,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                labelStyle: AppTextStyles.subtitleSmall,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
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
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailCtrl,
              readOnly: isGoogle,
              style: AppTextStyles.bodyMd.copyWith(
                color: isGoogle ? AppColors.textGraySoft : null,
              ),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Alamat Email',
                labelStyle: AppTextStyles.subtitleSmall,
                prefixIcon: Icon(
                  isGoogle
                      ? Icons.lock_outline_rounded
                      : Icons.mail_outline_rounded,
                  color: isGoogle ? AppColors.textGraySoft : AppColors.primary,
                ),
                filled: true,
                fillColor: isGoogle
                    ? AppColors.surfaceContainerHigh
                    : AppColors.surfaceContainerLow,
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
                onPressed: _isSubmitting ? null : _handleSubmit,
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
                        'Simpan Perubahan',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
