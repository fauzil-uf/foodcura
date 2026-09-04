import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'app_shimmer.dart';

// Widget gambar makanan efisien dengan dukungan disk/memory caching (CachedNetworkImage), aset lokal, dan fallback aman
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
    final uri = Uri.tryParse(path);
    final isNetwork =
        (path.startsWith('http://') || path.startsWith('https://')) &&
            uri != null &&
            uri.hasAuthority;

    final int? cacheW = (width > 0 && width.isFinite)
        ? (width * 2.5).clamp(40, 600).round()
        : null;
    final int? cacheH = (height > 0 && height.isFinite)
        ? (height * 2.5).clamp(40, 600).round()
        : null;

    Widget imageWidget;
    if (isNetwork) {
      // Menggunakan CachedNetworkImage untuk efisiensi penyimpanan lokal permanen (disk cache)
      // dan pembatasan konsumsi RAM (memCache) untuk menangani ribuan gambar makanan
      imageWidget = CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        maxWidthDiskCache: cacheW != null ? cacheW * 2 : null,
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            debugPrint('AppFoodImage error loading $url: $error');
          }
          return _buildFallback();
        },
      );
    } else {
      imageWidget = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return ClipRRect(borderRadius: effectiveBorderRadius, child: imageWidget);
  }

  Widget _buildPlaceholder() {
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF0EBE0),
      ),
    );
  }

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
