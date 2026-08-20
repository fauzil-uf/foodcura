import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../models/food_item_model.dart';
import '../../../models/food_log_model.dart';
import '../../widgets/app_food_image.dart';

/// Widget tampilan tab waktu makan spesifik (Sarapan, Makan Siang, Makan Malam, Camilan) dengan daftar log tercatat, tips gizi, dan saran cepat.
class FoodMealTab extends StatelessWidget {
  const FoodMealTab({
    super.key,
    required this.mealType,
    required this.logs,
    required this.totalCalories,
    required this.selectedDate,
    required this.recentCatalog,
    required this.recentlyAddedFoodNames,
    required this.onAddFood,
    required this.onOpenDetail,
    required this.onOpenAllCatalog,
    required this.onQuickAdd,
  });

  final String mealType;
  final List<FoodLogModel> logs;
  final int totalCalories;
  final DateTime selectedDate;
  final List<FoodItemModel> recentCatalog;
  final Set<String> recentlyAddedFoodNames;
  final ValueChanged<String> onAddFood;
  final ValueChanged<FoodLogModel> onOpenDetail;
  final VoidCallback onOpenAllCatalog;
  final Future<void> Function(FoodItemModel food, String mealType) onQuickAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateFormatter.formatToday(selectedDate),
                  style: AppTextStyles.subtitleSmall,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Total', style: AppTextStyles.subtitleSmall),
                Text(
                  '$totalCalories kcal',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.no_meals_outlined,
                  size: 44,
                  color: AppColors.textGray,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada makanan dicatat untuk $mealType',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildFoodLogCard(context, log);
            },
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            onPressed: () => onAddFood(mealType),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Tambah Makanan',
              style: AppTextStyles.button.copyWith(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Sehat',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTipForMeal(mealType),
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.primaryDark.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Terakhir Ditambahkan',
              style: AppTextStyles.heading2.copyWith(fontSize: 16),
            ),
            TextButton(
              onPressed: onOpenAllCatalog,
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.linkBold.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentCatalog.take(3).length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final food = recentCatalog[index];
            final isAdded = recentlyAddedFoodNames.contains(food.name);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  AppFoodImage(
                    imagePath: food.imagePath,
                    width: 56,
                    height: 56,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${food.calories} kcal · Baru saja',
                          style: AppTextStyles.subtitleSmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${food.calories}',
                    style: AppTextStyles.heading2.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: isAdded ? null : () => onQuickAdd(food, mealType),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isAdded
                                ? AppColors.mintTint
                                : AppColors.infoContainer,
                            shape: BoxShape.circle,
                            border: isAdded
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isAdded ? Icons.check_rounded : Icons.add,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFoodLogCard(BuildContext context, FoodLogModel log) {
    return GestureDetector(
      onTap: () => onOpenDetail(log),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            AppFoodImage(
              imagePath: log.imagePath,
              width: 60,
              height: 60,
              borderRadius: 16,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.foodName,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(log.time, style: AppTextStyles.subtitleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Protein ${log.protein}g · Karbo ${log.carbs}g · Lemak ${log.fat}g · Kol ${log.cholesterol.toInt()}mg',
                    style: AppTextStyles.subtitleSmall.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textGraySoft,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${log.calories}',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text('kcal', style: AppTextStyles.subtitleSmall),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Menghasilkan saran tips nutrisi singkat berdasarkan tipe waktu makan.
  String _getTipForMeal(String mealType) {
    switch (mealType) {
      case 'Sarapan':
        return 'Awali hari dengan sarapan yang mengandung karbohidrat dan protein agar energi lebih terjaga.';
      case 'Makan Siang':
        return 'Lengkapi makan siang dengan sumber karbohidrat, protein, dan sayuran agar lebih seimbang.';
      case 'Makan Malam':
        return 'Padukan sumber protein dengan sayuran untuk membuat makan malam lebih seimbang.';
      case 'Camilan':
        return 'Pilih camilan yang lebih mengenyangkan dan tetap perhatikan jumlah porsinya.';
      default:
        return 'Jaga pola makan seimbang setiap hari.';
    }
  }
}
