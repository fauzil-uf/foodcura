import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Widget visualisasi gambar makanan dan bahan dapur terpusat.
/// Mendukung URL online (Network), asset lokal, fallback icon elegan,
/// serta loading indicator otomatis.
class AppFoodImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;
  final IconData fallbackIcon;

  const AppFoodImage({
    super.key,
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.customBorderRadius,
    this.fallbackIcon = Icons.fastfood_rounded,
  });

  /// Merender gambar makanan baik dari URL network maupun asset lokal dengan pemotongan sudut melengkung (ClipRRect).
  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        customBorderRadius ?? BorderRadius.circular(borderRadius);

    if (imagePath == null || imagePath!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: _buildFallback(),
      );
    }

    final path = imagePath!.trim();
    final isNetwork =
        path.startsWith('http://') || path.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: imageWidget,
    );
  }

  /// Membangun placeholder visual elegan jika tautan gambar tidak ditemukan atau gagal dimuat.
  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0EBE0),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.primaryLight,
          size: width > 40 ? 24 : 16,
        ),
      ),
    );
  }
}
