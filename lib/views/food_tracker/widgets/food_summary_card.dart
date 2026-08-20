import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../controllers/food_tracker_controller.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_circular_progress.dart';

class FoodSummaryCard extends StatelessWidget {
  const FoodSummaryCard({
    super.key,
    required this.controller,
    required this.nutrientWarnings,
    required this.onAddFood,
    required this.onOpenMealTab,
  });

  final FoodTrackerController controller;
  final List<Map<String, dynamic>> nutrientWarnings;
  final void Function(String mealType) onAddFood;
  final void Function(int tabIndex) onOpenMealTab;

  @override
  Widget build(BuildContext context) {
    final totalCals = controller.totalCalories;
    final totalProtein = controller.totalProtein;
    final totalCarbs = controller.totalCarbs;
    final totalFat = controller.totalFat;
    final totalCholesterol = controller.totalCholesterol;

    final sarapanLogs = controller.sarapanLogs;
    final makanSiangLogs = controller.makanSiangLogs;
    final makanMalamLogs = controller.makanMalamLogs;
    final camilanLogs = controller.camilanLogs;

    // Hitung subtotal kalori per kategori makan menggunakan in-memory fold untuk performa render cepat.
    int sumCals(List<FoodLogModel> list) =>
        list.fold(0, (sum, item) => sum + item.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isToday
                              ? 'Ringkasan Nutrisi Hari Ini'
                              : 'Ringkasan Nutrisi (${controller.isYesterday ? 'Kemarin' : AppDateFormatter.formatShortDate(controller.selectedDate)})',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 16,
                            color: AppColors.deepForest,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppColors.textGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppDateFormatter.formatToday(controller.selectedDate),
                              style: AppTextStyles.subtitleSmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '2.000 kcal Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(110, 110),
                              painter: AppCircularProgressPainter(
                                progress: (totalCals / 2000).clamp(0.0, 1.0),
                                color: totalCals > 2000
                                    ? AppColors.error
                                    : AppColors.primary,
                                bgColor: AppColors.surfaceContainerHigh,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$totalCals',
                                  style: AppTextStyles.heading1.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: totalCals > 2000
                                        ? AppColors.error
                                        : AppColors.deepForest,
                                  ),
                                ),
                                Text(
                                  'kcal tercatat',
                                  style: AppTextStyles.subtitleSmall.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textGray,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalCals >= 2000
                                      ? 'Tercapai'
                                      : 'Sisa ${(2000 - totalCals).clamp(0, 2000)}',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: totalCals > 2000
                                        ? AppColors.error
                                        : AppColors.ecoGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: totalCals > 2000
                              ? AppColors.error.withValues(alpha: 0.12)
                              : (totalCals == 0
                                    ? AppColors.surfaceContainerLow
                                    : AppColors.primary.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          totalCals == 0
                              ? '0% tercapai'
                              : '${((totalCals / 2000) * 100).toStringAsFixed(1)}% tercapai',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: totalCals > 2000
                                ? AppColors.error
                                : (totalCals == 0
                                      ? AppColors.textGray
                                      : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildNutrientBar(
                          icon: Icons.egg_alt_outlined,
                          name: 'Protein',
                          valText: '${totalProtein.toInt()} / 65 g',
                          ratio: (totalProtein / 65).clamp(0.0, 1.0),
                          color: totalProtein > 65.0
                              ? AppColors.secondaryContainer
                              : AppColors.seaGreen,
                          iconBgColor: AppColors.seaGreen.withValues(alpha: 0.12),
                          isWarning: totalProtein > 65.0,
                        ),
                        _buildNutrientBar(
                          icon: Icons.bakery_dining_outlined,
                          name: 'Karbohidrat',
                          valText: '${totalCarbs.toInt()} / 300 g',
                          ratio: (totalCarbs / 300).clamp(0.0, 1.0),
                          color: totalCarbs > 300
                              ? AppColors.secondaryContainer
                              : AppColors.infoBlue,
                          iconBgColor: AppColors.infoBlue.withValues(alpha: 0.12),
                          isWarning: totalCarbs > 300,
                        ),
                        _buildNutrientBar(
                          icon: Icons.water_drop_outlined,
                          name: 'Lemak',
                          valText: '${totalFat.toInt()} / 67 g',
                          ratio: (totalFat / 67).clamp(0.0, 1.0),
                          color: totalFat >= 67.0
                              ? AppColors.error
                              : const Color(0xFFE65100),
                          iconBgColor: (totalFat >= 67.0
                                  ? AppColors.error
                                  : const Color(0xFFE65100))
                              .withValues(alpha: 0.12),
                          isWarning: totalFat >= 67.0,
                        ),
                        _buildNutrientBar(
                          icon: Icons.favorite_outline,
                          name: 'Kolesterol',
                          valText: '${totalCholesterol.toInt()} / 300 mg',
                          ratio: (totalCholesterol / 300).clamp(0.0, 1.0),
                          color: totalCholesterol > 300
                              ? AppColors.error
                              : const Color(0xFFD97706),
                          iconBgColor: const Color(0xFFD97706).withValues(
                            alpha: 0.12,
                          ),
                          isWarning: totalCholesterol > 300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (nutrientWarnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...nutrientWarnings.map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (w['color'] as Color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (w['color'] as Color).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (w['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      w['icon'] as IconData,
                      color: w['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w['title'] as String,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: w['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          w['message'] as String,
                          style: AppTextStyles.subtitleSmall.copyWith(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.isToday
                  ? 'Makanan Hari Ini'
                  : 'Makanan (${controller.isYesterday ? 'Kemarin' : AppDateFormatter.formatShortDate(controller.selectedDate)})',
              style: AppTextStyles.heading2.copyWith(fontSize: 16),
            ),
            if (!controller.isToday)
              GestureDetector(
                onTap: () => controller.setToday(),
                child: Text(
                  'Lihat Hari Ini',
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.allLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_outlined,
                    color: AppColors.textGraySoft,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.isToday
                      ? 'Belum Ada Santapan Hari Ini'
                      : 'Tidak Ada Catatan Makanan',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 15,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.isToday
                      ? 'Mulai hari sehatmu dengan mencatat sarapan atau santapan pertama!'
                      : 'Tidak ada makanan yang dicatat pada ${AppDateFormatter.formatToday(controller.selectedDate)}.',
                  style: AppTextStyles.subtitleSmall.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => onAddFood('Sarapan'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Catat Makanan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _buildMealCategoryCard(
            title: 'Sarapan',
            countText: '${sarapanLogs.length} makanan',
            calsText: '${sumCals(sarapanLogs)} kcal',
            icon: Icons.wb_twilight_rounded,
            iconColor: AppColors.seaGreen,
            onTap: () => onOpenMealTab(1),
          ),
          const SizedBox(height: 10),
          _buildMealCategoryCard(
            title: 'Makan Siang',
            countText: '${makanSiangLogs.length} makanan',
            calsText: '${sumCals(makanSiangLogs)} kcal',
            icon: Icons.light_mode_rounded,
            iconColor: AppColors.secondaryContainer,
            onTap: () => onOpenMealTab(2),
          ),
          const SizedBox(height: 10),
          _buildMealCategoryCard(
            title: 'Makan Malam',
            countText: '${makanMalamLogs.length} makanan',
            calsText: '${sumCals(makanMalamLogs)} kcal',
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.urgent,
            onTap: () => onOpenMealTab(3),
          ),
          const SizedBox(height: 10),
          _buildMealCategoryCard(
            title: 'Camilan',
            countText: '${camilanLogs.length} makanan',
            calsText: '${sumCals(camilanLogs)} kcal',
            icon: Icons.tapas_rounded,
            iconColor: AppColors.infoBlue,
            onTap: () => onOpenMealTab(4),
          ),
        ],
      ],
    );
  }

  Widget _buildMealCategoryCard({
    required String title,
    required String countText,
    required String calsText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final hasCals = !calsText.startsWith('0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countText,
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasCals
                        ? AppColors.mintTint
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasCals
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    calsText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: hasCals ? AppColors.primary : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGray,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBar({
    required IconData icon,
    required String name,
    required String valText,
    required double ratio,
    required Color color,
    required Color iconBgColor,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 11.5, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  if (isWarning) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
              Text(
                valText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? AppColors.error : AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
