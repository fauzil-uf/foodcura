import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/app_typography.dart';
import '../../../database/db_helper.dart';

/// Modal konfigurasi preferensi peringatan kedaluwarsa pantry, batas nutrisi, dan jadwal waktu makan harian.
class NotificationSettingsModal extends StatefulWidget {
  const NotificationSettingsModal({super.key});

  @override
  State<NotificationSettingsModal> createState() =>
      _NotificationSettingsModalState();
}

class _NotificationSettingsModalState extends State<NotificationSettingsModal> {
  bool _expiryAlert = true;
  bool _nutritionExcess = true;
  bool _dailyMealLog = true;
  bool _ecoTips = true;

  bool _breakfastEnabled = true;
  String _breakfastTime = '07:30';
  bool _lunchEnabled = true;
  String _lunchTime = '12:30';
  bool _dinnerEnabled = true;
  String _dinnerTime = '19:00';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expiryAlert = prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true;
      _nutritionExcess =
          prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true;
      _dailyMealLog = prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true;
      _ecoTips = prefs.getBool(AppConstants.keyNotifEcoTips) ?? true;

      _breakfastEnabled =
          prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true;
      _breakfastTime =
          prefs.getString(AppConstants.keyNotifBreakfastTime) ?? '07:30';
      _lunchEnabled = prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true;
      _lunchTime = prefs.getString(AppConstants.keyNotifLunchTime) ?? '12:30';
      _dinnerEnabled =
          prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true;
      _dinnerTime = prefs.getString(AppConstants.keyNotifDinnerTime) ?? '19:00';
      _isLoading = false;
    });
  }

  Future<void> _pickTime({
    required String currentTime,
    required Function(String) onSelected,
  }) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 7,
      minute: int.tryParse(parts[1]) ?? 30,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
      setState(() {
        onSelected(formatted);
      });
    }
  }

  /// Membangun modal lembar bawah berisi switch toggle preferensi notifikasi dan konfigurasi jam makan.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
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
                const Text(
                  'Pengaturan Notifikasi',
                  style: AppTextStyles.headlineMd,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Atur preferensi pengingat kedaluwarsa, nutrisi, dan jam makan.',
              style: AppTextStyles.subtitleSmall,
            ),
            const SizedBox(height: 18),
            _buildSwitchTile(
              title: 'Peringatan Makanan Kadaluwarsa',
              subtitle: 'Notifikasi H-2 & H-1 sebelum stok dapur basi',
              value: _expiryAlert,
              onChanged: (v) => setState(() => _expiryAlert = v),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            _buildSwitchTile(
              title: 'Peringatan Kelebihan Nutrisi',
              subtitle:
                  'Peringatan saat kalori, lemak, atau kolesterol melewati batas',
              value: _nutritionExcess,
              onChanged: (v) => setState(() => _nutritionExcess = v),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            _buildSwitchTile(
              title: 'Pengingat Log Makanan Harian',
              subtitle:
                  'Pengingat otomatis untuk mencatat sarapan, makan siang, dan makan malam',
              value: _dailyMealLog,
              onChanged: (v) => setState(() => _dailyMealLog = v),
            ),

            if (_dailyMealLog) ...[
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
                      time: _breakfastTime,
                      isEnabled: _breakfastEnabled,
                      onToggle: (v) => setState(() => _breakfastEnabled = v),
                      onPickTime: () => _pickTime(
                        currentTime: _breakfastTime,
                        onSelected: (t) => _breakfastTime = t,
                      ),
                    ),
                    const Divider(height: 12, color: AppColors.borderSoft),
                    _buildMealTimeRow(
                      icon: Icons.wb_sunny_rounded,
                      iconColor: const Color(0xFFE65100),
                      iconBg: const Color(0xFFFFF3E0),
                      label: 'Makan Siang',
                      time: _lunchTime,
                      isEnabled: _lunchEnabled,
                      onToggle: (v) => setState(() => _lunchEnabled = v),
                      onPickTime: () => _pickTime(
                        currentTime: _lunchTime,
                        onSelected: (t) => _lunchTime = t,
                      ),
                    ),
                    const Divider(height: 12, color: AppColors.borderSoft),
                    _buildMealTimeRow(
                      icon: Icons.bedtime_rounded,
                      iconColor: const Color(0xFFC62828),
                      iconBg: const Color(0xFFFFEBEE),
                      label: 'Makan Malam',
                      time: _dinnerTime,
                      isEnabled: _dinnerEnabled,
                      onToggle: (v) => setState(() => _dinnerEnabled = v),
                      onPickTime: () => _pickTime(
                        currentTime: _dinnerTime,
                        onSelected: (t) => _dinnerTime = t,
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
              value: _ecoTips,
              onChanged: (v) => setState(() => _ecoTips = v),
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
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(
                    AppConstants.keyNotifExpiryAlert,
                    _expiryAlert,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifNutritionExcess,
                    _nutritionExcess,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifDailyMealLog,
                    _dailyMealLog,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifEcoTips,
                    _ecoTips,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifBreakfastEnabled,
                    _breakfastEnabled,
                  );
                  await prefs.setString(
                    AppConstants.keyNotifBreakfastTime,
                    _breakfastTime,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifLunchEnabled,
                    _lunchEnabled,
                  );
                  await prefs.setString(
                    AppConstants.keyNotifLunchTime,
                    _lunchTime,
                  );
                  await prefs.setBool(
                    AppConstants.keyNotifDinnerEnabled,
                    _dinnerEnabled,
                  );
                  await prefs.setString(
                    AppConstants.keyNotifDinnerTime,
                    _dinnerTime,
                  );

                  await DBHelper().checkMealRemindersAndCreateNotifications();

                  if (context.mounted) {
                    Navigator.pop(context);
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
                child: const Text(
                  'Simpan Pengaturan',
                  style: AppTextStyles.buttonSmall,
                ),
              ),
            ),
          ],
        ),
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
}
