import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';


class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 58, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
              ),
              Positioned(
                right: 0,
                top: size * 0.12,
                child: Transform.rotate(
                  angle: -0.38,
                  child: Container(
                    width: size * 0.42,
                    height: size * 0.19,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size),
                        bottomRight: Radius.circular(size),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 9),
          Text(
            'FoodCura',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}
