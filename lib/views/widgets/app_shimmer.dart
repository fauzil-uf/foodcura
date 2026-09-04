import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Komponen terpusat untuk efek loading skeleton (Shimmer) berpalet hangat khas FoodCura.
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  static const Color defaultBaseColor = Color(0xFFEDE8DE);
  static const Color defaultHighlightColor = Color(0xFFFBF9F5);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? defaultBaseColor,
      highlightColor: highlightColor ?? defaultHighlightColor,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Kotak skeleton shimmer dengan radius sudut melengkung
class AppShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;

  const AppShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.customBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              customBorderRadius ?? BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Template skeleton kartu list untuk katalog makanan, pantry, dan artikel
class AppShimmerCard extends StatelessWidget {
  final double height;

  const AppShimmerCard({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          AppShimmerBox(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppShimmerBox(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                AppShimmerBox(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
