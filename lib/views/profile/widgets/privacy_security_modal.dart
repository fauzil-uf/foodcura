import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

class PrivacySecurityModal extends StatelessWidget {
  const PrivacySecurityModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
              Text(
                'Privasi & Keamanan Data',
                style: AppTextStyles.headlineMd,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Seluruh catatan nutrisi, riwayat makan, dan inventaris dapur tersimpan secara aman di basis data lokal SQLite perangkat Anda.',
            style: AppTextStyles.bodyMd.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '100% Bebas Pelacakan Pihak Ketiga & Terproteksi Penuh.',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: AppTextStyles.buttonSmall),
            ),
          ),
        ],
      ),
    );
  }
}
