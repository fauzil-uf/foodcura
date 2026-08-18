import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/auth_controller.dart';
import '../../database/db_helper.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_top_bar.dart';
import 'help_center_screen.dart';

/// Screen Profil pengguna bernuansa modern, konsisten, dan estetik
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authController = AuthController();
  UserModelSQL? _user;
  int _ecoPoints = 0;
  int _streak = 0;
  int _rescuedCount = 0;
  int _unreadNotifCount = 0;
  bool _isLoading = true;

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

    _loadProfileData();
    EcoPointsNotifier.instance.addListener(_onEcoChanged);
    EcoPointsNotifier.instance.init();
  }

  @override
  void dispose() {
    _animController.dispose();
    _authController.dispose();
    EcoPointsNotifier.instance.removeListener(_onEcoChanged);
    super.dispose();
  }

  void _onEcoChanged() {
    if (mounted) {
      setState(() => _ecoPoints = EcoPointsNotifier.instance.value);
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    await _authController.loadCurrentUser();
    final streakCount = await DBHelper().computeAndSaveStreak();
    final usedCount = await DBHelper().getUsedPantryItemsCount();
    final unread = await DBHelper().getUnreadNotificationCount();

    final prefs = await SharedPreferences.getInstance();
    final eco = prefs.getInt(EcoPointsNotifier.keyEcoPoints) ?? 0;

    if (mounted) {
      setState(() {
        _user = _authController.currentUser;
        _streak = streakCount;
        _ecoPoints = eco;
        _rescuedCount = usedCount;
        _unreadNotifCount = unread;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _loadProfileData());
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    final code = name.trim().toUpperCase().codeUnitAt(0);
    return _avatarColors[code % _avatarColors.length];
  }

  // ─── Edit Profil Modal ───────────────────────────────────────────────────
  Future<void> _showEditProfileModal() async {
    final nameCtrl = TextEditingController(text: _user?.name ?? '');
    final emailCtrl = TextEditingController(text: _user?.email ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  Text(
                    'Edit Informasi Profil',
                    style: AppTextStyles.headlineMd,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Perbarui nama lengkap dan alamat email akunmu.',
                style: AppTextStyles.subtitleSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
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
                controller: emailCtrl,
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
                    final newName = nameCtrl.text.trim();
                    final newEmail = emailCtrl.text.trim();
                    if (newName.isEmpty || newEmail.isEmpty) return;

                    final success = await _authController.updateProfile(
                      name: newName,
                      email: newEmail,
                    );
                    if (ctx.mounted) Navigator.pop(ctx, success);
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

  // ─── Notification Settings Modal ─────────────────────────────────────────
  Future<void> _showNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool expiryAlert = prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true;
    bool nutritionExcess =
        prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true;
    bool dailyMealLog =
        prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true;
    bool ecoTips = prefs.getBool(AppConstants.keyNotifEcoTips) ?? true;

    // Meal specific reminder settings
    bool breakfastEnabled =
        prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true;
    String breakfastTime =
        prefs.getString(AppConstants.keyNotifBreakfastTime) ?? '07:30';
    bool lunchEnabled =
        prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true;
    String lunchTime =
        prefs.getString(AppConstants.keyNotifLunchTime) ?? '12:30';
    bool dinnerEnabled =
        prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true;
    String dinnerTime =
        prefs.getString(AppConstants.keyNotifDinnerTime) ?? '19:00';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickTime({
            required String currentTime,
            required ValueChanged<String> onSelected,
          }) async {
            final parts = currentTime.split(':');
            final initial = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 12,
              minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
              helpText: 'Pilih Jam Pengingat Makan',
              cancelText: 'Batal',
              confirmText: 'Pilih',
              builder: (pickerCtx, child) {
                return Theme(
                  data: Theme.of(pickerCtx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: AppColors.deepForest,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              setModalState(() {
                onSelected(formatted);
              });
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
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
                          color: AppColors.infoContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pengaturan Notifikasi',
                        style: AppTextStyles.headlineMd,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur preferensi pengingat kedaluwarsa, nutrisi, dan jam makan.',
                    style: AppTextStyles.subtitleSmall,
                  ),
                  const SizedBox(height: 18),
                  _buildSwitchTile(
                    title: 'Peringatan Makanan Kadaluwarsa',
                    subtitle: 'Notifikasi H-2 & H-1 sebelum stok dapur basi',
                    value: expiryAlert,
                    onChanged: (v) => setModalState(() => expiryAlert = v),
                  ),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  _buildSwitchTile(
                    title: 'Peringatan Kelebihan Nutrisi',
                    subtitle:
                        'Peringatan saat kalori, lemak, atau kolesterol melewati batas',
                    value: nutritionExcess,
                    onChanged: (v) => setModalState(() => nutritionExcess = v),
                  ),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  _buildSwitchTile(
                    title: 'Pengingat Log Makanan Harian',
                    subtitle:
                        'Pengingat otomatis untuk mencatat sarapan, makan siang, dan makan malam',
                    value: dailyMealLog,
                    onChanged: (v) => setModalState(() => dailyMealLog = v),
                  ),

                  // Detail Jadwal Waktu Makan
                  if (dailyMealLog) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Jadwal & Waktu Pengingat Makan',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepForest,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildMealTimeRow(
                            icon: Icons.wb_twilight_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            iconBg: const Color(0xFFE8F5E9),
                            label: 'Sarapan',
                            time: breakfastTime,
                            isEnabled: breakfastEnabled,
                            onToggle: (v) =>
                                setModalState(() => breakfastEnabled = v),
                            onPickTime: () => pickTime(
                              currentTime: breakfastTime,
                              onSelected: (t) => breakfastTime = t,
                            ),
                          ),
                          const Divider(height: 12, color: AppColors.borderSoft),
                          _buildMealTimeRow(
                            icon: Icons.wb_sunny_rounded,
                            iconColor: const Color(0xFFE65100),
                            iconBg: const Color(0xFFFFF3E0),
                            label: 'Makan Siang',
                            time: lunchTime,
                            isEnabled: lunchEnabled,
                            onToggle: (v) =>
                                setModalState(() => lunchEnabled = v),
                            onPickTime: () => pickTime(
                              currentTime: lunchTime,
                              onSelected: (t) => lunchTime = t,
                            ),
                          ),
                          const Divider(height: 12, color: AppColors.borderSoft),
                          _buildMealTimeRow(
                            icon: Icons.bedtime_rounded,
                            iconColor: const Color(0xFFC62828),
                            iconBg: const Color(0xFFFFEBEE),
                            label: 'Makan Malam',
                            time: dinnerTime,
                            isEnabled: dinnerEnabled,
                            onToggle: (v) =>
                                setModalState(() => dinnerEnabled = v),
                            onPickTime: () => pickTime(
                              currentTime: dinnerTime,
                              onSelected: (t) => dinnerTime = t,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 1, color: AppColors.borderSoft),
                  _buildSwitchTile(
                    title: 'Tips Nutrisi & Eco Poin',
                    subtitle: 'Edukasi mingguan pencegahan food waste',
                    value: ecoTips,
                    onChanged: (v) => setModalState(() => ecoTips = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await prefs.setBool(
                          AppConstants.keyNotifExpiryAlert,
                          expiryAlert,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifNutritionExcess,
                          nutritionExcess,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifDailyMealLog,
                          dailyMealLog,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifEcoTips,
                          ecoTips,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifBreakfastEnabled,
                          breakfastEnabled,
                        );
                        await prefs.setString(
                          AppConstants.keyNotifBreakfastTime,
                          breakfastTime,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifLunchEnabled,
                          lunchEnabled,
                        );
                        await prefs.setString(
                          AppConstants.keyNotifLunchTime,
                          lunchTime,
                        );
                        await prefs.setBool(
                          AppConstants.keyNotifDinnerEnabled,
                          dinnerEnabled,
                        );
                        await prefs.setString(
                          AppConstants.keyNotifDinnerTime,
                          dinnerTime,
                        );

                        // Trigger meal reminders check immediately
                        await DBHelper().checkMealRemindersAndCreateNotifications();

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pengaturan notifikasi berhasil disimpan!',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Simpan Pengaturan',
                        style: AppTextStyles.buttonSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealTimeRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String time,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onPickTime,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isEnabled ? AppColors.deepForest : AppColors.textGray,
            ),
          ),
        ),
        GestureDetector(
          onTap: isEnabled ? onPickTime : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnabled ? AppColors.borderSoft : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: isEnabled ? AppColors.primary : AppColors.textGray,
                ),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? AppColors.primary : AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(
          value: isEnabled,
          activeTrackColor: AppColors.primary,
          onChanged: onToggle,
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.subtitleSmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ─── Privacy & Security Modal ────────────────────────────────────────────
  void _showPrivacyModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                    color: AppColors.mintTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.ecoGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Privasi & Keamanan Data',
                  style: AppTextStyles.headlineMd,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Seluruh catatan nutrisi, riwayat makan, dan inventaris dapur tersimpan secara aman di basis data lokal SQLite perangkat Anda.',
              style: AppTextStyles.bodyMd.copyWith(height: 1.5),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '100% Bebas Pelacakan Pihak Ketiga & Terproteksi Penuh.',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup', style: AppTextStyles.buttonSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── About FoodCura Dialog ───────────────────────────────────────────────
  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text('Tentang FoodCura', style: AppTextStyles.headlineSm),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FoodCura v2.0.0',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Aplikasi cerdas pelacak nutrisi harian dan pencegah food waste dengan dukungan Google Gemini AI.',
              style: AppTextStyles.subtitleSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Arsitektur MVC • Offline First • Powered by Gemini AI',
                style: AppTextStyles.label.copyWith(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ─── Logout Flow ─────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 10),
            Text('Keluar Akun', style: AppTextStyles.headlineSm),
          ],
        ),
        content: Text(
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
      await _authController.logout();
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
                      // Top App Bar
                      AppTopBar(
                        title: 'Profil',
                        unreadNotifications: _unreadNotifCount,
                        onNotificationTap: _openNotifications,
                      ),

                      // Main Scrollable Content
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

  // ─── Hero Profile Card (Gradient Mesh + Dynamic Avatar) ───────────────────
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
          // Background ambient circles for depth & premium aesthetics
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

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with glowing ring
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

                // User Info & Badges
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
                      // Join Date Chip
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

  // ─── Bento Stats Grid (Eco Points, Streak, Makanan Terselamatkan, Hemat) ───
  Widget _buildStatsBentoGrid() {
    final estKgCO2 = (_rescuedCount * 1.2).toStringAsFixed(1);
    final estHemat = _rescuedCount * 15000;

    return Column(
      children: [
        // Baris 1: Eco Points & Streak
        Row(
          children: [
            // Stat 1: Poin Eco
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Color(0xFFF57F17),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_ecoPoints',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepForest,
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Poin Eco',
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Stat 2: Streak Harian
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
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
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            size: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AKTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_streak Hari',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Streak Berturut',
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Baris 2: Makanan Terselamatkan & Penghematan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF81C784).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_rescuedCount Bahan Makanan Terselamatkan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20),
                        fontFamily: AppTextStyles.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mencegah ~$estKgCO2 kg emisi CO2 & menghemat ~Rp ${estHemat.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  // ─── Grouped Settings Menu ───────────────────────────────────────────────
  Widget _buildGroupedSettingsMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Akun & Preferensi
        Text('PENGATURAN & AKUN', style: AppTextStyles.sectionHeader),
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

        // Section: Keamanan & Privasi
        Text('KEAMANAN & PRIVASI', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        _buildMenuCard([
          _buildMenuTile(
            icon: Icons.lock_outline_rounded,
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF5E35B1),
            title: 'Privasi & Enkripsi Data',
            subtitle: 'Basis data lokal SQLite mandiri',
            onTap: _showPrivacyModal,
          ),
        ]),
        const SizedBox(height: 18),

        // Section: Bantuan & Komunitas
        Text('BANTUAN & INFORMASI', style: AppTextStyles.sectionHeader),
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
