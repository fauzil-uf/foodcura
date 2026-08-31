import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';

// Banner info edukasi transparansi pengiriman notifikasi lokal
class NotificationInfoTip extends StatelessWidget {
  const NotificationInfoTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active,
            color: AppColors.ecoGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kami hanya mengirim notifikasi penting terkait bahan makananmu dan pengingat yang kamu atur.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
