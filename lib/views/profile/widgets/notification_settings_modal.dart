import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/profile_controller.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_wheel_time_picker.dart';

/// Modal pengaturan preferensi notifikasi
class NotificationSettingsModal extends StatefulWidget {
  final ProfileController controller;

  const NotificationSettingsModal({super.key, required this.controller});

  @override
  State<NotificationSettingsModal> createState() =>
      _NotificationSettingsModalState();
}

class _NotificationSettingsModalState extends State<NotificationSettingsModal>
    with WidgetsBindingObserver {
  bool _expiryAlert = true;
  bool _nutritionExcess = true;
  bool _dailyMealLog = true;

  bool _breakfastEnabled = true;
  String _breakfastTime = '07:30';
  bool _lunchEnabled = true;
  String _lunchTime = '12:30';
  bool _dinnerEnabled = true;
  String _dinnerTime = '19:00';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _notificationsAllowed = true;
  bool _exactAlarmsAllowed = true;
  bool _batteryOptimizationIgnored = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat pengguna kembali dari Pengaturan OS (misal aktifkan izin notifikasi/alarm),
    // hanya periksa ulang status izin tanpa menimpa data form yang sedang diubah pengguna.
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  /// Muat status preferensi notifikasi dari controller saat modal pertama dibuka
  Future<void> _loadSettings() async {
    final settings = await widget.controller.loadNotificationSettings();
    final allowed = await widget.controller.areNotificationsEnabled();
    final exactAllowed = await widget.controller.canScheduleExactAlarms();
    final batteryIgnored = await widget.controller
        .isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _notificationsAllowed = allowed;
        _exactAlarmsAllowed = exactAllowed;
        _batteryOptimizationIgnored = batteryIgnored;
        _expiryAlert = settings['expiryAlert'] as bool;
        _nutritionExcess = settings['nutritionExcess'] as bool;
        _dailyMealLog = settings['dailyMealLog'] as bool;
        _breakfastEnabled = settings['breakfastEnabled'] as bool;
        _breakfastTime = settings['breakfastTime'] as String;
        _lunchEnabled = settings['lunchEnabled'] as bool;
        _lunchTime = settings['lunchTime'] as String;
        _dinnerEnabled = settings['dinnerEnabled'] as bool;
        _dinnerTime = settings['dinnerTime'] as String;
        _isLoading = false;
      });
    }
  }

  /// Periksa ulang izin sistem tanpa mereset data input form
  /// Jika exact alarm baru diaktifkan → reschedule alarm agar pakai exactAllowWhileIdle
  Future<void> _checkPermissions() async {
    final wasExactAllowed = _exactAlarmsAllowed;
    final allowed = await widget.controller.areNotificationsEnabled();
    final exactAllowed = await widget.controller.canScheduleExactAlarms();
    final batteryIgnored = await widget.controller
        .isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _notificationsAllowed = allowed;
        _exactAlarmsAllowed = exactAllowed;
        _batteryOptimizationIgnored = batteryIgnored;
      });
      // Jika exact alarm baru saja diizinkan, reschedule dengan mode tepat waktu
      if (!wasExactAllowed && exactAllowed) {
        await widget.controller.saveNotificationSettings(
          expiryAlert: _expiryAlert,
          nutritionExcess: _nutritionExcess,
          dailyMealLog: _dailyMealLog,
          ecoTips: false,
          breakfastEnabled: _breakfastEnabled,
          breakfastTime: _breakfastTime,
          lunchEnabled: _lunchEnabled,
          lunchTime: _lunchTime,
          dinnerEnabled: _dinnerEnabled,
          dinnerTime: _dinnerTime,
        );
      }
    }
  }

  /// Modal dialog pemilih jam dengan roda drag / scroll interaktif terpusat (format 24 jam)
  Future<void> _pickTime({
    required String currentTime,
    required String mealTitle,
    required IconData mealIcon,
    required Color iconColor,
    required Function(String) onSelected,
  }) async {
    final presets = mealTitle == 'Sarapan'
        ? const ['06:30', '07:00', '07:30', '08:00']
        : mealTitle == 'Makan Siang'
        ? const ['11:30', '12:00', '12:30', '13:00']
        : const ['18:30', '19:00', '19:30', '20:00'];

    final result = await AppWheelTimePickerSheet.show(
      context: context,
      initialTime: currentTime,
      title: 'Atur Waktu $mealTitle',
      subtitle: 'Geser roda ke atas/bawah untuk atur jam & menit',
      icon: mealIcon,
      iconColor: iconColor,
      presets: presets,
    );

    if (result != null && mounted) {
      setState(() {
        onSelected(result);
      });
    }
  }

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
            if (!_notificationsAllowed) ...[
              const SizedBox(height: 14),
              _buildStatusBanner(
                icon: Icons.notifications_off_outlined,
                color: AppColors.urgent,
                backgroundColor: AppColors.urgent.withValues(alpha: 0.08),
                borderColor: AppColors.urgent.withValues(alpha: 0.25),
                title: 'Izin Notifikasi Belum Aktif',
                subtitle:
                    'Aktifkan izin sistem agar notifikasi pengingat jam makan & stok bahan dapat muncul di perangkat.',
                actionLabel: 'Izinkan',
                onAction: () async {
                  final granted = await widget.controller
                      .requestNotificationPermissions();
                  if (!granted) {
                    await widget.controller.openNotificationSettings();
                  }
                  final allowed = await widget.controller
                      .areNotificationsEnabled();
                  if (mounted) {
                    setState(() {
                      _notificationsAllowed = allowed;
                    });
                  }
                },
              ),
            ],
            if (!_exactAlarmsAllowed) ...[
              const SizedBox(height: 10),
              _buildStatusBanner(
                icon: Icons.schedule_rounded,
                color: AppColors.infoBlueDark,
                backgroundColor: AppColors.infoBlueBg,
                borderColor: AppColors.infoBlueDark.withValues(alpha: 0.2),
                title: 'Presisi Pengingat (Opsional)',
                subtitle:
                    'Jadwal pengingat makan sudah aktif. Aktifkan izin "Alarm & Pengingat" jika ingin pengingat berdering persis di menit yang ditentukan.',
                actionLabel: 'Atur',
                onAction: () async {
                  await widget.controller.openExactAlarmSettings();
                  final wasAllowed = _exactAlarmsAllowed;
                  final exactAllowed = await widget.controller
                      .canScheduleExactAlarms();
                  if (mounted) {
                    setState(() {
                      _exactAlarmsAllowed = exactAllowed;
                    });
                    // Reschedule segera dengan exactAllowWhileIdle setelah izin diberikan
                    if (!wasAllowed && exactAllowed) {
                      await widget.controller.saveNotificationSettings(
                        expiryAlert: _expiryAlert,
                        nutritionExcess: _nutritionExcess,
                        dailyMealLog: _dailyMealLog,
                        ecoTips: false,
                        breakfastEnabled: _breakfastEnabled,
                        breakfastTime: _breakfastTime,
                        lunchEnabled: _lunchEnabled,
                        lunchTime: _lunchTime,
                        dinnerEnabled: _dinnerEnabled,
                        dinnerTime: _dinnerTime,
                      );
                    }
                  }
                },
              ),
            ],

            // Banner battery optimization — tampil jika app masih dioptimasi baterai
            if (_exactAlarmsAllowed && !_batteryOptimizationIgnored) ...[
              const SizedBox(height: 8),
              _buildStatusBanner(
                icon: Icons.battery_alert_rounded,
                color: const Color(0xFFE65100),
                backgroundColor: const Color(0xFFFFF8E1),
                borderColor: const Color(0xFFFFB300).withValues(alpha: 0.4),
                title: 'Penggunaan Baterai Dibatasi',
                subtitle:
                    'Notifikasi mungkin terlambat. Set FoodCura ke "Tidak terbatas" agar tepat waktu.',
                actionLabel: 'Atur',
                onAction: () async {
                  await widget.controller.openBatteryOptimizationSettings();
                },
              ),
            ],
            const SizedBox(height: 18),
            _buildSwitchTile(
              title: 'Peringatan Bahan Kedaluwarsa',
              subtitle:
                  'Notifikasi berkala sebelum bahan mencapai batas simpan',
              value: _expiryAlert,
              onChanged: (v) => setState(() => _expiryAlert = v),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            _buildSwitchTile(
              title: 'Peringatan Kelebihan Nutrisi',
              subtitle:
                  'Peringatan saat kalori, lemak, atau kolesterol melewati batas harian',
              value: _nutritionExcess,
              onChanged: (v) => setState(() => _nutritionExcess = v),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            _buildSwitchTile(
              title: 'Pengingat Waktu Makan',
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
                        mealTitle: 'Sarapan',
                        mealIcon: Icons.wb_twilight_rounded,
                        iconColor: const Color(0xFF2E7D32),
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
                        mealTitle: 'Makan Siang',
                        mealIcon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFFE65100),
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
                        mealTitle: 'Makan Malam',
                        mealIcon: Icons.bedtime_rounded,
                        iconColor: const Color(0xFFC62828),
                        onSelected: (t) => _dinnerTime = t,
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        try {
                          final allowed = await widget.controller
                              .areNotificationsEnabled();
                          if (!allowed) {
                            await widget.controller
                                .requestNotificationPermissions();
                          }

                          await widget.controller.saveNotificationSettings(
                            expiryAlert: _expiryAlert,
                            nutritionExcess: _nutritionExcess,
                            dailyMealLog: _dailyMealLog,
                            ecoTips: false,
                            breakfastEnabled: _breakfastEnabled,
                            breakfastTime: _breakfastTime,
                            lunchEnabled: _lunchEnabled,
                            lunchTime: _lunchTime,
                            dinnerEnabled: _dinnerEnabled,
                            dinnerTime: _dinnerTime,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            AppSnackBar.showSuccess(
                              context,
                              'Pengaturan & jadwal notifikasi berhasil disimpan!',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackBar.showError(
                              context,
                              'Gagal menyimpan pengaturan: $e',
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSaving = false);
                          }
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
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

  /// Baris item jadwal waktu makan beserta switch aktif/nonaktif dan pemilih jam
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

  /// Baris opsi pengaturan dengan switch toggle
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

  /// Banner status izin sistem & pengoptimalan baterai yang terpusat dan konsisten
  Widget _buildStatusBanner({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.subtitleSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
