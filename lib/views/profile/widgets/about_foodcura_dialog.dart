import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/app_images.dart';
import '../../../constants/app_typography.dart';

// Dialog informasi dan identitas aplikasi FoodCura
class AboutFoodCuraDialog extends StatelessWidget {
  const AboutFoodCuraDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(AppImages.logo, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // App Name
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Food',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepForest,
                    fontSize: 20,
                  ),
                ),
                TextSpan(
                  text: 'Cura',
                  style: AppTextStyles.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Version Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FoodCura ${AppConstants.appVersionDisplay}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Terbaru',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Short Description
          Text(
            'Aplikasi cerdas pelacak nutrisi harian dan pencegah food waste dengan dukungan Google Gemini AI.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitleSmall.copyWith(
              fontSize: 12.5,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Feature Highlights Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                _buildFeatureRow(
                  Icons.restaurant_menu_rounded,
                  'Pelacak Nutrisi & Kalori Harian',
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  Icons.inventory_2_outlined,
                  'Manajemen Stok Dapur & Kedaluwarsa',
                ),
                const SizedBox(height: 8),
                _buildFeatureRow(
                  Icons.auto_awesome_rounded,
                  'Asisten Cerdas Google Gemini AI',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Button: Tutup
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Text link: Lihat Lisensi Open Source
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.pop(context);
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersionDisplay,
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      AppImages.logo,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                applicationLegalese:
                    '© 2026 FoodCura • Lisensi MIT (Open Source)',
              );
            },
            icon: const Icon(
              Icons.description_outlined,
              size: 14,
              color: AppColors.textGray,
            ),
            label: Text(
              'Lihat Lisensi Open Source',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textGray.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.deepForest,
            ),
          ),
        ),
      ],
    );
  }
}
