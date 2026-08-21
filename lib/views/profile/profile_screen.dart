import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_top_bar.dart';
import 'help_center_screen.dart';
import 'widgets/about_foodcura_dialog.dart';
import 'widgets/edit_profile_modal.dart';
import 'widgets/notification_settings_modal.dart';
import 'widgets/privacy_security_modal.dart';

/// Screen Profil pengguna bernuansa modern, konsisten, dan estetik
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

  // Google Account style vibrant avatar palette
  static const List<Color> _avatarColors = [
    Color(0xFF1E8E3E), // Emerald Green
    Color(0xFF1A73E8), // Google Blue
    Color(0xFFD93025), // Crimson Red
    Color(0xFFF29900), // Vibrant Amber
    Color(0xFF8430CE), // Royal Purple
    Color(0xFF00796B), // Deep Teal
    Color(0xFFE65100), // Sunset Orange
    Color(0xFF00838F), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _profileController.initListeners();
    _profileController.addListener(_onProfileChanged);
    _loadProfileData();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _profileController.removeListener(_onProfileChanged);
    _profileController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// Memuat data profil pengguna aktif, streak harian, eco-points, dan notifikasi dari SQLite via ProfileController.
  Future<void> _loadProfileData() async {
    await _profileController.loadProfile();
    if (mounted) {
      _animController.forward(from: 0);
    }
  }

  /// Membuka layar notifikasi dan me-refresh data profil setelah pengguna kembali.
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _profileController.refreshNotifications());
  }

  /// Menghasilkan warna latar avatar yang konsisten berdasarkan inisial nama pengguna.
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final code = name.trim().toUpperCase().codeUnitAt(0);
    return _avatarColors[code % _avatarColors.length];
  }

  /// Membuka modal form untuk mengubah nama lengkap dan alamat email pengguna.
  Future<void> _showEditProfileModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileModal(
        user: _user,
        controller: _profileController,
      ),
    );

    if (result == true) {
      _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil berhasil diperbarui!',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.ecoGreen,
          ),
        );
      }
    }
  }

  /// Membuka modal konfigurasi waktu pengingat makan dan peringatan kedaluwarsa.
  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NotificationSettingsModal(),
    );
  }

  /// Membuka modal informasi kebijakan privasi dan keamanan penyimpanan offline.
  void _showPrivacyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PrivacySecurityModal(),
    );
  }

  /// Membuka dialog tentang versi aplikasi dan visi FoodCura.
  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (_) => const AboutFoodCuraDialog(),
    );
  }

  /// Menampilkan dialog konfirmasi dan membersihkan sesi akun pengguna saat keluar.
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Keluar Akun', style: AppTextStyles.headlineSm),
          ],
        ),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari akun FoodCura?',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: AppTextStyles.linkBold.copyWith(color: AppColors.textGray),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _profileController.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Membangun antarmuka profil pengguna dengan kartu hero, bento grid statistik poin/streak, dan menu pengaturan akun.
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
                                _buildHeroProfileCard(),
                                const SizedBox(height: 18),
                                _buildStatsBentoGrid(),
                                const SizedBox(height: 20),
                                _buildGroupedSettingsMenu(),
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

  /// Membangun kartu profil utama dengan avatar dinamis, nama, email, dan tanggal bergabung.
  Widget _buildHeroProfileCard() {
    final name = _user?.name.trim().isNotEmpty == true
        ? _user!.name.trim()
        : 'Pengguna FoodCura';
    final email = _user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarBg = _getAvatarColor(name);
    final joinDateStr = _user?.createdAt;

    DateTime? joinDate;
    if (joinDateStr != null && joinDateStr.isNotEmpty) {
      joinDate = DateTime.tryParse(joinDateStr) ??
          AppDateFormatter.parseDate(joinDateStr);
    }
    final formattedDate = joinDate != null
        ? AppDateFormatter.formatShortDate(joinDate)
        : AppDateFormatter.formatShortDate();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143E24), Color(0xFF0A2213)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143E24).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyles.fontFamily,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email.isNotEmpty ? email : 'user@foodcura.app',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          fontFamily: AppTextStyles.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: Color(0xFF81C784),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Bergabung sejak $formattedDate',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTextStyles.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun grid bento 2 kartu untuk menampilkan total Eco Poin dan streak harian.
  Widget _buildStatsBentoGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF81C784).withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.ecoGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_ecoPoints',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Eco Poin',
                  style: AppTextStyles.subtitleSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE65100),
                    fontFamily: AppTextStyles.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hari Streak',
                  style: AppTextStyles.subtitleSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBF360C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun daftar menu navigasi pengaturan yang dikelompokkan ke dalam kartu terpisah.
  Widget _buildGroupedSettingsMenu() {
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
            onTap: _showEditProfileModal,
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          _buildMenuTile(
            icon: Icons.notifications_none_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1976D2),
            title: 'Pengaturan Notifikasi',
            subtitle: 'Pengingat kadaluwarsa & log harian',
            onTap: _showNotificationSettings,
          ),
        ]),
        const SizedBox(height: 18),

        const Text('KEAMANAN & PRIVASI', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
          _buildMenuTile(
            icon: Icons.shield_outlined,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
            title: 'Privasi & Keamanan Data',
            subtitle: 'Pengelolaan data lokal & layanan online',
            onTap: _showPrivacyModal,
          ),
        ]),
        const SizedBox(height: 18),

        const Text('BANTUAN & INFORMASI', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
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
            subtitle: 'FoodCura v2.0.0 (MVC Architecture)',
            onTap: _showAboutAppDialog,
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
              onTap: _logout,
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
