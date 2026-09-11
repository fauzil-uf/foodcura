import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

/// Dialog konfirmasi terstandar untuk seluruh aplikasi
class AppDialog {
  AppDialog._();

  /// Dialog konfirmasi (hapus item, keluar akun, dll)
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? highlightedItem,
    String confirmLabel = 'Hapus',
    String cancelLabel = 'Batal',
    Color confirmColor = AppColors.error,
    IconData icon = Icons.delete_outline_rounded,
    Color iconColor = AppColors.error,
    Color iconBgColor = AppColors.errorContainer,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 28)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.deepForest,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (highlightedItem != null && highlightedItem.isNotEmpty)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13.5,
                    color: AppColors.textGray,
                    height: 1.45,
                  ),
                  children: [
                    TextSpan(text: '$message '),
                    TextSpan(
                      text: highlightedItem,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              )
            else
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  fontSize: 13.5,
                  color: AppColors.textGray,
                  height: 1.45,
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      cancelLabel,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      confirmLabel,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}
