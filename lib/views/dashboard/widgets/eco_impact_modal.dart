import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/pantry_item_model.dart';
import '../../../services/gemini_service.dart';

/// Modal feedback apresiasi dampak penyelamatan makanan (Finansial & Lingkungan)
/// Muncul sebagai feedback interaktif setelah menekan 'Tandai Habis'.
class EcoImpactModal extends StatelessWidget {
  final PantryItemModel item;
  final EcoImpactResult impactResult;
  final VoidCallback onDismiss;

  const EcoImpactModal({
    super.key,
    required this.item,
    required this.impactResult,
    required this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required PantryItemModel item,
    required EcoImpactResult impactResult,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcoImpactModal(
        item: item,
        impactResult: impactResult,
        onDismiss: onDismiss ?? () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedRupiah = impactResult.savedRupiah.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
      (m) => "${m[1]}.",
    );

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

          // Eco Icon Badge
          Container(
            width: 68,
            height: 68,
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
              child: Icon(Icons.check_circle_rounded, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Subtitle
          Text(
            'Bahan Berhasil Dihabiskan!',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              color: AppColors.deepForest,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 13,
                color: AppColors.textGray,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Aksi hebat! Kamu telah mengolah '),
                TextSpan(
                  text: item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepForest,
                  ),
                ),
                const TextSpan(text: ' tepat waktu sebelum terbuang.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2 Impact Metrics (Rupiah Hemat & CO2 Tercegah)
          Row(
            children: [
              // Saved Money
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFFE65100),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp $formattedRupiah',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFFE65100),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Estimasi Uang Hemat',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF8D6E63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Prevented CO2
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.forest_rounded,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${impactResult.kgCO2} kg CO₂',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF2E7D32),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Emisi Jejak Tercegah',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // AI / Category Narrative Insight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mintTint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.ecoGreen.withValues(alpha: 0.2),
              ),
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
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.ecoGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Dampak bagi Lingkungan',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ecoGreen,
                          ),
                        ),
                      ],
                    ),
                    if (impactResult.isAiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '✨ Gemini AI',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  impactResult.narrative,
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
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
                'Selesai',
                style: AppTextStyles.button.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
