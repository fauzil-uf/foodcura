import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_date_formatter.dart';
import '../../../constants/app_typography.dart';
import '../../../models/pantry_item_model.dart';
import '../../widgets/app_food_image.dart';

// Kartu item bahan pantry dengan progress bar kedaluwarsa & tombol aksi
class PantryItemCard extends StatelessWidget {
  final PantryItemModel item;
  final VoidCallback onTap;
  final VoidCallback onMarkUsed;

  const PantryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkUsed,
  });

  @override
  Widget build(BuildContext context) {
    final days = item.daysUntilExpiry;
    Color statusColor;
    switch (item.expiryStatus) {
      case 'expired':
      case 'urgent':
        statusColor = AppColors.urgent;
        break;
      case 'segera':
        statusColor = AppColors.segera;
        break;
      default:
        statusColor = AppColors.ecoGreen;
    }

    final expiryLabel = days < 0
        ? 'Kadaluwarsa'
        : days == 0
        ? 'Hari ini'
        : '$days hari lagi';

    final formattedDate = AppDateFormatter.formatShortDate(item.expiryDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceDim),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppFoodImage(
              imagePath: item.imageUrl,
              width: 72,
              height: 72,
              borderRadius: 16,
              fallbackIcon: Icons.kitchen_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepForest,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textGray,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.quantityDisplay,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: item.expiryProgress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            expiryLabel,
                            style: AppTextStyles.badgeText.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            '($formattedDate)',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onMarkUsed,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tandai Habis',
                            style: AppTextStyles.buttonSmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
