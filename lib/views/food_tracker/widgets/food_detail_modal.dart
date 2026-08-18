import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../database/db_helper.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_food_image.dart';

class FoodDetailModal extends StatefulWidget {
  final FoodLogModel log;
  final VoidCallback onLogDeleted;

  const FoodDetailModal({
    super.key,
    required this.log,
    required this.onLogDeleted,
  });

  @override
  State<FoodDetailModal> createState() => _FoodDetailModalState();
}

class _FoodDetailModalState extends State<FoodDetailModal> {
  late TextEditingController _noteController;
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.log.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _deleteFood() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Hapus Catatan Makanan',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepForest,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // RichText with bold food name
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13.5,
                    color: AppColors.textGray,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'Apakah Anda yakin ingin menghapus '),
                    TextSpan(
                      text: widget.log.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const TextSpan(
                      text: ' dari riwayat catatan harian ini?',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Batal',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Hapus',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true && widget.log.id != null) {
      await DBHelper().deleteFoodLog(widget.log.id!);
      widget.onLogDeleted();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.log.foodName} berhasil dihapus'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (widget.log.id != null) {
      final updatedLog = FoodLogModel(
        id: widget.log.id,
        userId: widget.log.userId,
        foodName: widget.log.foodName,
        mealType: widget.log.mealType,
        calories: widget.log.calories,
        protein: widget.log.protein,
        carbs: widget.log.carbs,
        fat: widget.log.fat,
        imagePath: widget.log.imagePath,
        time: widget.log.time,
        date: widget.log.date,
        note: _noteController.text.trim(),
      );
      await DBHelper().updateFoodLog(updatedLog);
      widget.onLogDeleted();
      setState(() {
        _isEditingNote = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 6,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textGray),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Detail Makanan',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 48, height: 48),
              ],
            ),
            const SizedBox(height: 12),

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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.foodName,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${log.calories} ',
                                    style: AppTextStyles.heading1.copyWith(
                                      fontSize: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'kcal',
                                    style: AppTextStyles.subtitleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.time} · ${log.date}',
                          style: AppTextStyles.subtitleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.infoContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.mealType,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nutritional Info Grid (5 Metric boxes)
            Text(
              'Informasi Gizi (per porsi)',
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricCard('${log.calories}', 'Kkal', AppColors.primary),
                const SizedBox(width: 6),
                _buildMetricCard(
                  '${log.protein}g',
                  'Protein',
                  const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  '${log.carbs}g',
                  'Karbo',
                  const Color(0xFF1976D2),
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  '${log.fat}g',
                  'Lemak',
                  const Color(0xFFE65100),
                ),
                const SizedBox(width: 6),
                _buildMetricCard(
                  '${log.cholesterol.toStringAsFixed(0)}mg',
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
    );
  }

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
