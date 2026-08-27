import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_images.dart';
import '../../../constants/app_typography.dart';

/// Dialog informasi versi aplikasi, arsitektur MVC, dan teknologi cerdas Google Gemini AI.
class AboutFoodCuraDialog extends StatelessWidget {
  const AboutFoodCuraDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              AppImages.logo,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Food',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepForest,
                  ),
                ),
                TextSpan(
                  text: 'Cura',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FoodCura v2.1.0',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aplikasi cerdas pelacak nutrisi harian dan pencegah food waste dengan dukungan Google Gemini AI.',
            style: AppTextStyles.subtitleSmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Arsitektur MVC • Offline First • Powered by Gemini AI',
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                color: AppColors.textGray,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
