import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

// Banner ringkasan peringatan jumlah bahan rawan kedaluwarsa
class PantrySummaryAlert extends StatelessWidget {
  final int count;

  const PantrySummaryAlert({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBgLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.segera.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.segera,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count bahan perlu segera digunakan',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gunakan sebelum kadaluwarsa untuk mengurangi food waste.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
