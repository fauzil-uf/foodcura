import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/profile_controller.dart';
import '../../../models/user_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            const SizedBox(height: 20),
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
              style: AppTextStyles.bodyMd,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Alamat Email',
                labelStyle: AppTextStyles.subtitleSmall,
                prefixIcon: const Icon(
                  Icons.mail_outline_rounded,
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
                onPressed: () async {
                  final newName = _nameCtrl.text.trim();
                  final newEmail = _emailCtrl.text.trim();
                  if (newName.isEmpty || newEmail.isEmpty) return;

                  final success = await widget.controller.updateProfile(
                    name: newName,
                    email: newEmail,
                  );
                  if (context.mounted) Navigator.pop(context, success);
                },
                child: Text(
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
