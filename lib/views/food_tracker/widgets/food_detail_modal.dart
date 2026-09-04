import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_food_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/food_tracker_controller.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_food_image.dart';
import '../../widgets/app_snack_bar.dart';

// Modal detail nutrisi & edit catatan makanan
class FoodDetailModal extends StatefulWidget {
  final FoodLogModel log;
  final FoodTrackerController? controller;
  final VoidCallback? onLogDeleted;

  const FoodDetailModal({
    super.key,
    required this.log,
    this.controller,
    this.onLogDeleted,
  });

  @override
  State<FoodDetailModal> createState() => _FoodDetailModalState();
}

class _FoodDetailModalState extends State<FoodDetailModal> {
  late final FoodTrackerController _controller;
  late TextEditingController _noteController;
  late FoodLogModel _currentLog;
  bool _isEditingNote = false;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FoodTrackerController();
    _currentLog = widget.log;
    _noteController = TextEditingController(text: widget.log.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Tampilkan dialog konfirmasi dan hapus catatan makanan dari database
  Future<void> _deleteFood() async {
    final confirm = await AppDialog.showConfirmDialog(
      context: context,
      title: 'Hapus Catatan Makanan',
      message: 'Apakah kamu yakin ingin menghapus',
      highlightedItem: _currentLog.foodName,
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
    );

    if (confirm == true && _currentLog.id != null) {
      await _controller.deleteFoodLog(_currentLog.id!);
      widget.onLogDeleted?.call();
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(
          context,
          '${_currentLog.foodName} berhasil dihapus',
        );
      }
    }
  }

  // Simpan perubahan catatan kustom pada log makanan ke database
  Future<void> _saveNote() async {
    if (_currentLog.id != null && !_isSavingNote) {
      setState(() => _isSavingNote = true);
      final updatedLog = _currentLog.copyWith(note: _noteController.text.trim());
      await _controller.updateFoodLog(updatedLog);
      widget.onLogDeleted?.call();
      if (mounted) {
        setState(() {
          _currentLog = updatedLog;
          _isEditingNote = false;
          _isSavingNote = false;
        });
        AppSnackBar.showSuccess(
          context,
          'Catatan berhasil disimpan',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = _currentLog;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Statis (Drag Handle + Judul + Tombol Tutup)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      'Detail Makanan',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, color: AppColors.textGray, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Konten Scrollable (Keyboard-Safe)
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AppFoodImage(
                          imagePath: log.imagePath,
                          width: 70,
                          height: 70,
                          borderRadius: 16,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mintTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.mealType,
                                  style: AppTextStyles.subtitleSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppFoodFormatter.cleanDisplayName(log.foodName),
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${log.time} · ${log.calories} kcal',
                                style: AppTextStyles.subtitleSmall.copyWith(
                                  color: AppColors.textGray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nutrition Breakdown Grid (4 Metrics)
                  Row(
                    children: [
                      _buildMetricCard(
                        '${log.protein.toStringAsFixed(1)}g',
                        'Protein',
                        const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        '${log.carbs.toStringAsFixed(1)}g',
                        'Karbo',
                        const Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        '${log.fat.toStringAsFixed(1)}g',
                        'Lemak',
                        const Color(0xFFE65100),
                      ),
                      const SizedBox(width: 8),
                      _buildMetricCard(
                        '${log.cholesterol.toInt()}mg',
                        'Kolesterol',
                        const Color(0xFF8E24AA),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Catatan Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.edit_note,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Catatan',
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isEditingNote)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEditingNote = true;
                                  });
                                },
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isEditingNote)
                          Column(
                            children: [
                              TextField(
                                controller: _noteController,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Tulis catatan makanan...',
                                  filled: true,
                                  fillColor: AppColors.inputFillSoft,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _saveNote,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Simpan'),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            (log.note != null && log.note!.isNotEmpty)
                                ? log.note!
                                : 'Tidak ada catatan.',
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 13,
                              color: (log.note != null && log.note!.isNotEmpty)
                                  ? AppColors.textPrimary
                                  : AppColors.textGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isEditingNote = true;
                            });
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            'Edit Catatan',
                            style: AppTextStyles.button.copyWith(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _deleteFood,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu metrik ringkas nilai nutrisi per porsi
  Widget _buildMetricCard(String val, String label, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 13.5,
                color: valColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
