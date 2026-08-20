import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter lingkaran progress ring untuk kalori & nutrisi di Dashboard dan Food Tracker.
/// Mengeliminasi duplikasi class CustomPainter di kedua layar utama.
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

  /// Menggambar lintasan lingkaran latar belakang dan busur progres aktif searah jarum jam (-90 derajat awal).
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

  /// Menentukan apakah canvas perlu digambar ulang saat nilai progres atau warna berubah.
  @override
  bool shouldRepaint(covariant AppCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
