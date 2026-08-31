import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_images.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../services/app_notifiers.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/about_foodcura_dialog.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/notification_settings_modal.dart';
import 'widgets/privacy_security_modal.dart';
import 'widgets/profile_hero_card.dart';
import 'widgets/profile_settings_menu.dart';
import 'widgets/profile_stats_bento.dart';

// Layar profil pengguna & pengaturan akun
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
    Color(0xFF1B5E20),
    Color(0xFF2E7D32),
    Color(0xFF388E3C),
    Color(0xFF43A047),
    Color(0xFF00695C),
    Color(0xFF00897B),
    Color(0xFF0277BD),
    Color(0xFF1565C0),
    Color(0xFF283593),
    Color(0xFF4527A0),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFFC2185B),
    Color(0xFFD81B60),
    Color(0xFFE65100),
    Color(0xFFEF6C00),
    Color(0xFFF57C00),
    Color(0xFF4E342E),
    Color(0xFF37474F),
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
    PantryUpdateNotifier.instance.addListener(_loadProfileData);
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
                          onRefresh: _loadProfileData,
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
                                  onPrivacyPolicy: _showPrivacyModal,
                                  onAboutApp: _showAboutAppDialog,
                                  onOpenSourceLicenses:
                                      _showOpenSourceLicenses,
                                  onLogout: _logout,
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
