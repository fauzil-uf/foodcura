import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

/// Modal bottom sheet pemilih waktu interaktif bergaya roda putar (drag wheel) 24 jam.
//// Dapat digunakan secara terpusat di seluruh fitur aplikasi (pengaturan notifikasi, food log, dll).
class AppWheelTimePickerSheet extends StatefulWidget {
  final String initialTime;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final List<String> presets;

  const AppWheelTimePickerSheet({
    super.key,
    required this.initialTime,
    required this.title,
    this.subtitle,
    this.icon = Icons.access_time_rounded,
    this.iconColor = AppColors.primary,
    this.presets = const [],
  });

  /// Menampilkan bottom sheet pemilih waktu dan mengembalikan string format 'HH:mm'.
  static Future<String?> show({
    required BuildContext context,
    required String initialTime,
    required String title,
    String? subtitle,
    IconData icon = Icons.access_time_rounded,
    Color iconColor = AppColors.primary,
    List<String> presets = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppWheelTimePickerSheet(
        initialTime: initialTime,
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        presets: presets,
      ),
    );
  }

  @override
  State<AppWheelTimePickerSheet> createState() =>
      _AppWheelTimePickerSheetState();
}

class _AppWheelTimePickerSheetState extends State<AppWheelTimePickerSheet> {
  late DateTime _selectedDateTime;
  int _pickerKeyCounter = 0;

  @override
  void initState() {
    super.initState();
    final parts = widget.initialTime.split(':');
    final initialHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 7) : 7;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    _selectedDateTime = DateTime(
      2026,
      1,
      1,
      initialHour.clamp(0, 23),
      initialMinute.clamp(0, 59),
    );
  }

  String get _formattedTime {
    final h = _selectedDateTime.hour.toString().padLeft(2, '0');
    final m = _selectedDateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _onPresetTapped(String preset) {
    final parts = preset.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final min = int.tryParse(parts[1]);
      if (hour != null && min != null) {
        setState(() {
          _selectedDateTime = DateTime(2026, 1, 1, hour, min);
          _pickerKeyCounter++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar drag atas
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header title & badge icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 18,
                            color: AppColors.deepForest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle ??
                              'Geser roda ke atas/bawah untuk atur jam & menit',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Badge pratinjau jam digital live
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.mintTint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.alarm_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_formattedTime WIB',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 26,
                        letterSpacing: 1.2,
                        color: AppColors.deepForest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Roda putar interaktif CupertinoDatePicker
              SizedBox(
                height: 180,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: AppTextStyles.heading2.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepForest,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    key: ValueKey('wheel_picker_$_pickerKeyCounter'),
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: _selectedDateTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      setState(() {
                        _selectedDateTime = newDateTime;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Chip preset cepat (jika tersedia)
              if (widget.presets.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.presets.map((preset) {
                      final isCurrentPreset = _formattedTime == preset;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => _onPresetTapped(preset),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentPreset
                                  ? AppColors.primary
                                  : AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrentPreset
                                    ? AppColors.primary
                                    : AppColors.borderSoft,
                              ),
                            ),
                            child: Text(
                              preset,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCurrentPreset
                                    ? Colors.white
                                    : AppColors.deepForest,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
              ] else
                const SizedBox(height: 8),

              // Tombol Batal & Terapkan
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepForest,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _formattedTime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
