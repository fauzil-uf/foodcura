import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_images.dart';
import '../../constants/app_typography.dart';

/// Top App Bar terpusat dan reusable untuk seluruh layar utama FoodCura.
/// Menghilangkan ratusan baris duplikasi styling header, logo, dan badge notifikasi.
class AppTopBar extends StatelessWidget {
  final String? title;
  final bool showBrandLogo;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    this.title,
    this.showBrandLogo = false,
    this.showBackButton = false,
    this.onBack,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.actions,
  });

  /// Membangun bilah header atas dengan judul/logo di sisi kiri dan tombol aksi atau lonceng notifikasi di sisi kanan.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5EE),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5DFC9), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C3A3222),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBrandLogo)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppImages.logo,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Food',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.deepForest,
                        ),
                      ),
                      TextSpan(
                        text: 'Cura',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (showBackButton)
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6D8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDFD7C2), width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.deepForest,
                ),
              ),
            )
          else
            const SizedBox(width: 42, height: 42),

          if (!showBrandLogo && title != null)
            Text(
              title!,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.deepForest,
              ),
            ),

          if (actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: actions!)
          else if (onNotificationTap != null)
            GestureDetector(
              onTap: onNotificationTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6D8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDFD7C2), width: 1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.deepForest,
                      size: 22,
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        top: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.urgent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            unreadNotifications > 9
                                ? '9+'
                                : '$unreadNotifications',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }
}
