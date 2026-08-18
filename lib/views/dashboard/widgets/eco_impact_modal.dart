import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/pantry_item_model.dart';

/// Modal apresiasi dampak lingkungan (Eco Impact & Savings) saat bahan makanan diselamatkan
class EcoImpactModal extends StatelessWidget {
  final PantryItemModel item;
  final String impactNarrative;
  final int earnedPoints;
  final VoidCallback onDismiss;

  const EcoImpactModal({
    super.key,
    required this.item,
    required this.impactNarrative,
    this.earnedPoints = 10,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required PantryItemModel item,
    required String impactNarrative,
    int earnedPoints = 10,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcoImpactModal(
        item: item,
        impactNarrative: impactNarrative,
        earnedPoints: earnedPoints,
        onDismiss: onDismiss ?? () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Eco Celebration Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ecoGreen.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, size: 38, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Text(
            'Makanan Terselamatkan!',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 22,
              color: AppColors.deepForest,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Kamu berhasil mengolah "${item.name}" sebelum kedaluwarsa.',
            style: AppTextStyles.subtitleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Badges Grid (Eco Points + Zero Waste)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+$earnedPoints Poin',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Eco Points Didapat',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.savings_rounded,
                            color: Color(0xFFE65100),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '~Rp 15.000',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimasi Hemat',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // AI Narrative Insight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mintTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.ecoGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.ecoGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dampak Nyata bagi Lingkungan',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ecoGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  impactNarrative,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                onDismiss();
              },
              child: Text(
                'Lanjutkan Menjaga Bumi',
                style: AppTextStyles.button.copyWith(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
