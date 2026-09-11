import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Widget cincin progres melingkar untuk ringkasan kalori dan nutrisi
class AppCircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final Color bgColor;
  final double strokeWidth;
  final Widget? child;

  const AppCircularProgress({
    super.key,
    required this.progress,
    this.size = 108,
    this.color = AppColors.primary,
    this.bgColor = AppColors.surfaceContainerHigh,
    this.strokeWidth = 9.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: AppCircularProgressPainter(
              progress: progress,
              color: color,
              bgColor: bgColor,
              strokeWidth: strokeWidth,
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// CustomPainter untuk menggambar ring progres kalori dan makronutrien
class AppCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  const AppCircularProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    this.strokeWidth = 9.0,
  });

  /// Gambar lingkaran latar belakang dan busur progres
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant AppCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
