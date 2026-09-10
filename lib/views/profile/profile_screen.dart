import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../services/app_notifiers.dart';
import '../../services/app_update_service.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/about_foodcura_dialog.dart';
import 'widgets/change_password_modal.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/notification_settings_modal.dart';
import 'widgets/privacy_security_modal.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/profile_settings_menu.dart';
import 'widgets/profile_stats_bento.dart';

/// Layar profil pengguna & pengaturan akun.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _profileController = ProfileController();

  UserModelSQL? get _user => _profileController.user;
  int get _streak => _profileController.streak;
  int get _ecoPoints => _profileController.ecoPoints;
  int get _unreadNotifCount => _profileController.unreadNotifications;
  bool get _isLoading => _profileController.isLoading;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Palet warna acak avatar berdasarkan nama user
  static const List<Color> _avatarColors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFC2185B),
    Color(0xFF4527A0),
    Color(0xFF00695C),
    Color(0xFFD84315),
    Color(0xFF283593),
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF43A047),
    Color(0xFF00695C),
  ];

  @override
  void initState() {
    super.initState();
    // Animasi entrance fade & slide-up halus
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    // Inisialisasi controller dan listener
    _profileController.initListeners();
    _profileController.addListener(_onProfileChanged);
    _profileController.startCloudSync();
    PantryUpdateNotifier.instance.addListener(_loadProfileData);
    UserProfileUpdateNotifier.instance.addListener(_loadProfileData);
    NotificationNotifier.instance.addListener(_onNotifChanged);
    _loadProfileData();
  }

  // Update tampilan saat data profil berubah
  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  // Refresh count notifikasi unread
  void _onNotifChanged() {
    if (mounted) _profileController.refreshNotifications();
  }

  @override
  void dispose() {
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    UserProfileUpdateNotifier.instance.removeListener(_loadProfileData);
    PantryUpdateNotifier.instance.removeListener(_loadProfileData);
    _profileController.removeListener(_onProfileChanged);
    _profileController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Muat data profil user, streak, dan poin dari database
  Future<void> _loadProfileData() async {
    await _profileController.loadProfile();
    if (mounted) {
      _animController.forward(from: 0);
    }
  }

  // Buka layar notifikasi
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _profileController.refreshNotifications());
  }

  // Hitung warna latar avatar berdasarkan karakter pertama nama
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final code = name.trim().toUpperCase().codeUnitAt(0);
    return _avatarColors[code % _avatarColors.length];
  }

  // Buka modal edit profil user (nama & email)
  Future<void> _showEditProfileModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditProfileModal(user: _user, controller: _profileController),
    );

    if (result == true) {
      _loadProfileData();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Profil berhasil diperbarui!');
      }
    }
  }

  // Buka modal pengaturan notifikasi dan jam makan
  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          NotificationSettingsModal(controller: _profileController),
    );
  }

  // Buka modal sinkronisasi Cloud Firestore
  void _showCloudSyncModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isSyncing = _profileController.isSyncing;
          final lastSync = _profileController.lastSyncTime;
          final lastSyncText = lastSync != null
              ? '${lastSync.day.toString().padLeft(2, '0')}/${lastSync.month.toString().padLeft(2, '0')}/${lastSync.year} ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
              : 'Belum pernah';

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE7F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: Color(0xFF5E35B1),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sinkronisasi Cloud Firestore',
                  style: AppTextStyles.headlineMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cadangkan seluruh bahan dapur, riwayat nutrisi, dan preferensi Anda ke server Google agar aman dan tersinkronisasi saat ganti perangkat.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textGray),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                          'Terakhir: $lastSyncText',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isSyncing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF5E35B1)),
                        SizedBox(height: 12),
                        Text('Sedang menyinkronkan data...', style: AppTextStyles.caption),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setModalState(() {});
                        final res = await _profileController.backupAllToCloud();
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        if (res.success) {
                          AppSnackBar.showSuccess(context, res.message ?? 'Cadangan cloud berhasil!');
                        } else {
                          AppSnackBar.showError(context, res.message ?? 'Gagal mencadangkan ke cloud.');
                        }
                        _loadProfileData();
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                      label: const Text(
                        'Cadangkan ke Cloud (Backup)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        setModalState(() {});
                        final res = await _profileController.restoreFromCloud();
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        if (res.success) {
                          AppSnackBar.showSuccess(context, res.message ?? 'Pemulihan cloud berhasil!');
                        } else {
                          AppSnackBar.showError(context, res.message ?? 'Gagal memulihkan dari cloud.');
                        }
                        _loadProfileData();
                      },
                      icon: const Icon(Icons.cloud_download_outlined, color: Color(0xFF5E35B1)),
                      label: const Text(
                        'Pulihkan dari Cloud (Restore)',
                        style: TextStyle(color: Color(0xFF5E35B1), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5E35B1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // Buka modal ganti kata sandi akun
  void _showChangePasswordModal() {
    if (_user?.isGoogleAccount == true) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.mintTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Akun Google Terhubung',
                style: AppTextStyles.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Akun Anda (${_user?.email ?? ""}) terdaftar dan diamankan menggunakan Google Sign-In. Pengelolaan keamanan, verifikasi 2 langkah, dan kata sandi dikelola langsung oleh akun Google Anda.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangePasswordModal(
        user: _user,
        controller: _profileController,
      ),
    );
  }

  // Buka modal kebijakan privasi dan keamanan data
  void _showPrivacyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacySecurityModal(),
    );
  }

  // Tampilkan dialog informasi rilis dan versi aplikasi FoodCura
  void _showAboutAppDialog() {
    showDialog(context: context, builder: (_) => const AboutFoodCuraDialog());
  }

  // Periksa pembaruan langsung ke Google Play Store via In-App Update API
  void _showCheckUpdates() {
    AppUpdateService.checkForPlayStoreUpdate(context);
  }

  // Tampilkan halaman lisensi open source pustaka pihak ketiga
  void _showOpenSourceLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersionDisplay,
      applicationIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            AppImages.logo,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      ),
      applicationLegalese: '© 2026 FoodCura • Lisensi MIT (Open Source)',
    );
  }

  // Tampilkan dialog konfirmasi dan proses keluar akun
  Future<void> _logout() async {
    final confirm = await AppDialog.showConfirmDialog(
      context: context,
      title: 'Keluar Akun',
      message: 'Apakah kamu yakin ingin keluar dari akun FoodCura?',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout_rounded,
      confirmColor: AppColors.error,
    );

    if (confirm && mounted) {
      await _profileController.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      AppTopBar(
                        title: 'Profil',
                        unreadNotifications: _unreadNotifCount,
                        onNotificationTap: _openNotifications,
                      ),

                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            await _profileController.syncCloudProfile();
                            if (mounted) {
                              _animController.forward(from: 0);
                            }
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              top: 18,
                              bottom: 120,
                              left: 18,
                              right: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileHeroCard(
                                  user: _user,
                                  avatarBg: _getAvatarColor(_user?.name ?? ''),
                                ),
                                const SizedBox(height: 18),
                                ProfileStatsBento(
                                  ecoPoints: _ecoPoints,
                                  streak: _streak,
                                ),
                                const SizedBox(height: 20),
                                ProfileSettingsMenu(
                                  onEditProfile: _showEditProfileModal,
                                  onNotificationSettings:
                                      _showNotificationSettings,
                                  onCloudSync: _showCloudSyncModal,
                                  onChangePassword: _showChangePasswordModal,
                                  onPrivacyPolicy: _showPrivacyModal,
                                  onAboutApp: _showAboutAppDialog,
                                  onOpenSourceLicenses:
                                      _showOpenSourceLicenses,
                                  onCheckUpdates: _showCheckUpdates,
                                  onLogout: _logout,
                                  isGoogleAccount:
                                      _user?.isGoogleAccount ?? false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
