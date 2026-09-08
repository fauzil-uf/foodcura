import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/app_typography.dart';
import '../help_center_screen.dart';

// Kelompok menu pengaturan akun, keamanan & privasi, serta logout
class ProfileSettingsMenu extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onNotificationSettings;
  final VoidCallback onChangePassword;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onAboutApp;
  final VoidCallback onOpenSourceLicenses;
  final VoidCallback? onCheckUpdates;
  final VoidCallback onLogout;
  final bool isGoogleAccount;

  const ProfileSettingsMenu({
    super.key,
    required this.onEditProfile,
    required this.onNotificationSettings,
    required this.onChangePassword,
    required this.onPrivacyPolicy,
    required this.onAboutApp,
    required this.onOpenSourceLicenses,
    this.onCheckUpdates,
    required this.onLogout,
    this.isGoogleAccount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PENGATURAN & AKUN', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
          _buildMenuTile(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
            title: 'Edit Informasi Profil',
            subtitle: 'Ubah nama dan alamat email',
            onTap: onEditProfile,
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          _buildMenuTile(
            icon: Icons.notifications_none_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            title: 'Pengaturan Notifikasi',
            subtitle: 'Pengingat kedaluwarsa & log harian',
            onTap: onNotificationSettings,
          ),
        ]),
        const SizedBox(height: 18),

        const Text('KEAMANAN & PRIVASI', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
          if (!isGoogleAccount) ...[
            _buildMenuTile(
              icon: Icons.lock_reset_rounded,
              iconBg: const Color(0xFFFFF8E1),
              iconColor: const Color(0xFFF57F17),
              title: 'Ganti Kata Sandi',
              subtitle: 'Perbarui kata sandi akun untuk keamanan',
              onTap: onChangePassword,
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
          ] else ...[
            _buildMenuTile(
              icon: Icons.verified_user_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: AppColors.primary,
              title: 'Keamanan Akun Google',
              subtitle: 'Akun terhubung & diamankan via Google',
              onTap: onChangePassword,
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
          ],
          _buildMenuTile(
            icon: Icons.shield_outlined,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
            title: 'Privasi & Keamanan Data',
            subtitle: 'Pengelolaan data lokal & layanan online',
            onTap: onPrivacyPolicy,
          ),
        ]),
        const SizedBox(height: 18),

        const Text('BANTUAN & INFORMASI', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
          _buildMenuTile(
            icon: Icons.system_update_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
            title: 'Periksa Pembaruan',
            subtitle:
                'FoodCura ${AppConstants.appVersionDisplay} • Sistem up-to-date',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${AppConstants.appVersionDisplay} Terbaru',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ),
            onTap: onCheckUpdates ?? () {},
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          _buildMenuTile(
            icon: Icons.help_outline_rounded,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            title: 'Pusat Bantuan & FAQ',
            subtitle: 'Panduan lengkap fitur & kontak kami',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          _buildMenuTile(
            icon: Icons.info_outline_rounded,
            iconBg: const Color(0xFFE0F2F1),
            iconColor: const Color(0xFF00796B),
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi & pengembang',
            onTap: onAboutApp,
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          _buildMenuTile(
            icon: Icons.description_outlined,
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF512DA8),
            title: 'Lisensi Open Source',
            subtitle: 'Daftar lisensi pustaka & atribusi pihak ketiga',
            onTap: onOpenSourceLicenses,
          ),
        ]),
        const SizedBox(height: 22),

        // Logout Button Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.errorContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.errorText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keluar dari Akun',
                            style: AppTextStyles.bodyMdDanger.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Sesi aktif akan diakhiri dengan aman',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              color: AppColors.errorText.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.errorText,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, size: 20, color: iconColor)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.surfaceDim,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
