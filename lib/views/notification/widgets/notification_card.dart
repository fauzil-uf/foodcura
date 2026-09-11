import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/notification_model.dart';

/// Kartu item notifikasi dengan ikon tipe, status belum dibaca, dan badge kategori
class NotificationCard extends StatelessWidget {
  final NotificationModel notif;
  final bool isEarlier;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NotificationCard({
    super.key,
    required this.notif,
    this.isEarlier = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color accentColor;
    Color iconBgColor;
    String categoryTag;

    switch (notif.type) {
      case NotificationModel.typeMealReminder:
        categoryTag = 'Pengingat Makan';
        accentColor = AppColors.primary;
        iconData = Icons.restaurant_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case NotificationModel.typeExpiryWarning:
        final lowerTitle = notif.title.toLowerCase();
        final lowerMsg = notif.message.toLowerCase();
        final isUrgent =
            lowerTitle.contains('hari ini') ||
            lowerTitle.contains('besok') ||
            lowerTitle.contains('telah') ||
            lowerTitle.contains('lewat') ||
            lowerMsg.contains('1 hari') ||
            lowerTitle.contains('urgent');
        final isWarning =
            lowerTitle.contains('mendekati') ||
            lowerMsg.contains('2 hari') ||
            lowerMsg.contains('3 hari') ||
            lowerMsg.contains('4 hari');

        if (isUrgent) {
          categoryTag = 'Kedaluwarsa';
          accentColor = AppColors.urgent;
          iconData = Icons.warning_amber_rounded;
          iconBgColor = AppColors.warningBg;
        } else if (isWarning) {
          categoryTag = 'Mendekati Kedaluwarsa';
          accentColor = AppColors.segera;
          iconData = Icons.access_time_rounded;
          iconBgColor = AppColors.warningBgLight;
        } else {
          categoryTag = 'Pengingat Stok';
          accentColor = AppColors.primary;
          iconData = Icons.kitchen_rounded;
          iconBgColor = AppColors.mintTint;
        }
        break;
      case NotificationModel.typeNutritionExcess:
        categoryTag = 'Batas Nutrisi';
        accentColor = AppColors.nutritionViolet;
        iconData = Icons.insights_rounded;
        iconBgColor = AppColors.nutritionVioletBg;
        break;
      case NotificationModel.typeTips:
        categoryTag = 'Tips & Edukasi';
        accentColor = AppColors.ecoGreen;
        iconData = notif.iconType == NotificationModel.iconRestaurant
            ? Icons.restaurant_rounded
            : Icons.lightbulb_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case NotificationModel.typeSystem:
      default:
        categoryTag = 'Info Sistem';
        accentColor = AppColors.infoBlueDark;
        iconData = notif.iconType == NotificationModel.iconEco
            ? Icons.eco_rounded
            : Icons.system_update_rounded;
        iconBgColor = AppColors.infoBlueBg;
        break;
    }

    final displayTitle = notif.title
        .replaceAll('kadaluwarsa', 'kedaluwarsa')
        .replaceAll('Kadaluwarsa', 'Kedaluwarsa')
        .replaceAll('[URGENT] ', '');
    final displayMessage = notif.message
        .replaceAll('kadaluwarsa', 'kedaluwarsa')
        .replaceAll('Kadaluwarsa', 'Kedaluwarsa');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mintTint.withValues(alpha: 0.35)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : notif.isRead
                ? AppColors.surfaceDim
                : accentColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : (notif.isRead ? 1 : 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.deepForest.withValues(alpha: 0.05),
              blurRadius: isSelected ? 24 : 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent border strip
                Container(
                  width: 5,
                  color: isSelected
                      ? AppColors.primary
                      : notif.isRead
                      ? accentColor.withValues(alpha: 0.4)
                      : accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Opacity(
                      opacity: isEarlier ? 0.85 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSelectionMode) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 10, right: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textGray.withValues(
                                          alpha: 0.5,
                                        ),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        categoryTag,
                                        style: AppTextStyles.badgeText.copyWith(
                                          fontSize: 10,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  displayTitle,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: notif.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppColors.deepForest,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),

                                Text(
                                  displayMessage,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                Text(
                                  notif.timeAgo,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
