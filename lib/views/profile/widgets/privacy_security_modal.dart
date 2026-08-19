import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

/// Modal informasi Privasi & Keamanan Data.
/// Menjelaskan penggunaan penyimpanan lokal dan layanan online secara ringkas dan transparan.
class PrivacySecurityModal extends StatelessWidget {
  const PrivacySecurityModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.mintTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.ecoGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Privasi & Keamanan Data',
                  style: AppTextStyles.headlineMd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Introduction
          Text(
            'FoodCura menggunakan penyimpanan lokal dan layanan online sesuai kebutuhan fitur.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.deepForest.withValues(alpha: 0.85),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // 3 Compact Information Items
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              children: [
                _buildInfoItem(
                  icon: Icons.storage_rounded,
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: AppColors.primary,
                  title: 'Penyimpanan Lokal',
                  subtitle:
                      'Data aplikasi tertentu disimpan secara lokal di perangkat.',
                ),
                const Divider(height: 18, color: AppColors.borderSoft),
                _buildInfoItem(
                  icon: Icons.cloud_outlined,
                  iconBg: const Color(0xFFE1F5FE),
                  iconColor: const Color(0xFF0277BD),
                  title: 'Layanan Online',
                  subtitle:
                      'Beberapa resource, seperti gambar makanan, membutuhkan koneksi internet.',
                ),
                const Divider(height: 18, color: AppColors.borderSoft),
                _buildInfoItem(
                  icon: Icons.auto_awesome_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFE65100),
                  title: 'Gemini AI',
                  subtitle:
                      'Fitur AI membutuhkan koneksi internet untuk memproses permintaan.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Button Tutup
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: AppTextStyles.buttonSmall),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.deepForest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGray,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
