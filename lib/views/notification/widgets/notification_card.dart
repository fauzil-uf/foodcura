import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_typography.dart';
import '../../../models/notification_model.dart';

// Kartu item notifikasi dengan ikon tipe, status belum dibaca, dan badge kategori
class NotificationCard extends StatelessWidget {
  final NotificationModel notif;
  final bool isEarlier;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notif,
    this.isEarlier = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color accentColor;
    Color iconBgColor;
    String categoryTag;

    switch (notif.type) {
      case 'meal_reminder':
        categoryTag = 'Pengingat Waktu Makan';
        accentColor = AppColors.primary;
        iconData = Icons.restaurant_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case 'expiry_warning':
        categoryTag = 'Pantry & Expiry';
        accentColor = AppColors.urgent;
        iconData = Icons.warning_amber_rounded;
        iconBgColor = AppColors.warningBg;
        break;
      case 'nutrition_excess':
        categoryTag = 'Tracker Nutrisi';
        accentColor = AppColors.segera;
        iconData = Icons.analytics_rounded;
        iconBgColor = AppColors.warningBgLight;
        break;
      case 'tips':
        categoryTag = 'Tips Food Rescue';
        accentColor = AppColors.ecoGreen;
        iconData = notif.iconType == 'restaurant'
            ? Icons.restaurant_rounded
            : Icons.lightbulb_rounded;
        iconBgColor = AppColors.mintTint;
        break;
      case 'system':
      default:
        categoryTag = 'System & Info';
        accentColor = AppColors.infoBlueDark;
        iconData = notif.iconType == 'eco'
            ? Icons.eco_rounded
            : Icons.system_update_rounded;
        iconBgColor = AppColors.infoBlueBg;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notif.isRead
                ? AppColors.surfaceDim
                : accentColor.withValues(alpha: 0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepForest.withValues(alpha: 0.05),
              blurRadius: 20,
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
                  color: notif.isRead
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
                                  notif.title,
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
                                  notif.message,
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
