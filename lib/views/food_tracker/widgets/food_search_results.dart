import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/food_item_model.dart';
import '../../widgets/app_food_image.dart';

class FoodSearchResults extends StatelessWidget {
  const FoodSearchResults({
    super.key,
    required this.searchQuery,
    required this.searchResults,
    required this.currentMealType,
    required this.recentlyAddedFoodNames,
    required this.onClear,
    required this.onQuickAdd,
  });

  final String searchQuery;
  final List<FoodItemModel> searchResults;
  final String currentMealType;
  final Set<String> recentlyAddedFoodNames;
  final VoidCallback onClear;
  final Future<void> Function(FoodItemModel food, String mealType) onQuickAdd;

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Tidak ada makanan cocok dengan "$searchQuery"',
            style: AppTextStyles.subtitle,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hasil Pencarian (${searchResults.length})',
                style: AppTextStyles.heading2.copyWith(fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final food = searchResults[index];
              final isAdded = recentlyAddedFoodNames.contains(food.name);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: isAdded
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    AppFoodImage(
                      imagePath: food.imagePath,
                      width: 50,
                      height: 50,
                      borderRadius: 12,
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
                          Text(
                            '${food.calories} kcal · ${food.category}',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdded ? AppColors.mintTint : AppColors.primary,
                          elevation: isAdded ? 0 : 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isAdded
                                ? const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: isAdded
                            ? null
                            : () => onQuickAdd(food, currentMealType),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdded ? Icons.check_rounded : Icons.add_rounded,
                              size: 16,
                              color: isAdded ? AppColors.primary : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAdded ? 'Tercatat' : 'Tambah',
                              style: AppTextStyles.buttonSmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isAdded ? AppColors.primary : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
