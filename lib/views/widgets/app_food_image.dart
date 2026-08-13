import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AppFoodImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;

  const AppFoodImage({
    super.key,
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        imagePath,
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
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageWidget,
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.fastfood,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }
}
