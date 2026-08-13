import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_date_formatter.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToTracker;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTracker,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalCalories = 1245;
  final int _targetCalories = 2000;
  double _proteinGrams = 45.0;
  final double _proteinMax = 65.0;
  double _carbsGrams = 180.0;
  final double _carbsMax = 300.0;
  double _lemakJenuhGrams = 18.0;
  final double _lemakJenuhMax = 25.0;
  double _kolesterolMg = 180.0;
  final double _kolesterolMax = 300.0;
  int _unreadNotifsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryFromDB();
  }

  Future<void> _fetchSummaryFromDB() async {
    final logs = await DBHelper().getFoodLogs(date: AppDateFormatter.formatToday());
    final unread = await DBHelper().getUnreadNotificationCount();
    if (mounted) {
      int totalCals = 0;
      double totalFat = 0;
      double totalProt = 0;
      double totalCarbs = 0;
      for (var log in logs) {
        totalCals += log.calories;
        totalFat += log.fat;
        totalProt += log.protein;
        totalCarbs += log.carbs;
      }
      setState(() {
        _totalCalories = totalCals;
        _proteinGrams = totalProt > 0 ? totalProt : 45.0;
        _carbsGrams = totalCarbs > 0 ? totalCarbs : 180.0;
        _lemakJenuhGrams = totalFat > 0 ? totalFat : 18.0;
        _kolesterolMg = (totalFat * 4.5 + totalProt * 3.5) > 0
            ? (totalFat * 4.5 + totalProt * 3.5)
            : 180.0;
        _unreadNotifsCount = unread;
      });
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _fetchSummaryFromDB());
  }

  @override
  Widget build(BuildContext context) {
    final progressRatio = (_totalCalories / _targetCalories).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, Fauzil!',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Yuk, jalani hari sehatmu! ',
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const Text('🌱', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                        ),
                        if (_unreadNotifsCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                _unreadNotifsCount > 9 ? '9+' : '$_unreadNotifsCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nutrition Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Nutrisi Hari Ini',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppDateFormatter.formatToday(),
                      style: AppTextStyles.subtitleSmall,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        // Circular Progress Ring & Percentage
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(110, 110),
                                    painter: _CircularProgressPainter(
                                      progress: progressRatio,
                                      color: AppColors.primary,
                                      bgColor: const Color(0xFFF3F4F6),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$_totalCalories',
                                        style: AppTextStyles.heading1.copyWith(
                                          fontSize: 20,
                                          height: 1.0,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '/ $_targetCalories',
                                        style: AppTextStyles.subtitleSmall.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        'kcal',
                                        style: AppTextStyles.subtitleSmall.copyWith(
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.infoContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(progressRatio * 100).toStringAsFixed(1)}%',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),

                        // Horizontal Macro Progress Bars
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Protein Bar
                              _buildMacroLinearBar(
                                label: 'Protein',
                                valueText:
                                    '${_proteinGrams.toStringAsFixed(0)} g',
                                maxText:
                                    '/ ${_proteinMax.toStringAsFixed(0)} g',
                                percentageText:
                                    '${((_proteinGrams / _proteinMax) * 100).toInt()}%',
                                ratio: (_proteinGrams / _proteinMax)
                                    .clamp(0.0, 1.0),
                                barColor: AppColors.ecoGreen,
                              ),
                              const SizedBox(height: 10),

                              // Karbohidrat Bar
                              _buildMacroLinearBar(
                                label: 'Karbohidrat',
                                valueText:
                                    '${_carbsGrams.toStringAsFixed(0)} g',
                                maxText:
                                    '/ ${_carbsMax.toStringAsFixed(0)} g',
                                percentageText:
                                    '${((_carbsGrams / _carbsMax) * 100).toInt()}%',
                                ratio: (_carbsGrams / _carbsMax)
                                    .clamp(0.0, 1.0),
                                barColor: const Color(0xFF3B82F6), // Blue
                              ),
                              const SizedBox(height: 10),

                              // Lemak Jenuh Bar
                              _buildMacroLinearBar(
                                label: 'Lemak Jenuh',
                                valueText:
                                    '${_lemakJenuhGrams.toStringAsFixed(0)} g',
                                maxText:
                                    '/ ${_lemakJenuhMax.toStringAsFixed(0)} g',
                                percentageText:
                                    '${((_lemakJenuhGrams / _lemakJenuhMax) * 100).toInt()}%',
                                ratio: (_lemakJenuhGrams / _lemakJenuhMax)
                                    .clamp(0.0, 1.0),
                                barColor: _lemakJenuhGrams >= _lemakJenuhMax
                                    ? AppColors.error
                                    : const Color(0xFFF97316),
                              ),
                              const SizedBox(height: 10),

                              // Kolesterol Bar
                              _buildMacroLinearBar(
                                label: 'Kolesterol',
                                valueText:
                                    '${_kolesterolMg.toStringAsFixed(0)} mg',
                                maxText:
                                    '/ ${_kolesterolMax.toStringAsFixed(0)} mg',
                                percentageText:
                                    '${((_kolesterolMg / _kolesterolMax) * 100).toInt()}%',
                                ratio: (_kolesterolMg / _kolesterolMax)
                                    .clamp(0.0, 1.0),
                                barColor: const Color(0xFFEAB308), // Yellow
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // "Lihat Detail" link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: widget.onNavigateToTracker,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Detail',
                              style: AppTextStyles.linkBold.copyWith(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bento Grid Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgent Stock Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stok Urgent',
                                    style: AppTextStyles.heading2.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Akan kadaluwarsa',
                                    style: AppTextStyles.subtitleSmall.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '3 item',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Item 1: Bayam
                          _buildUrgentItem(
                            name: 'Bayam',
                            timeText: '1 hari lagi',
                            timeColor: Colors.redAccent,
                            imagePath: 'assets/images/food/bayam.png',
                          ),
                          const SizedBox(height: 10),

                          // Item 2: Susu UHT
                          _buildUrgentItem(
                            name: 'Susu UHT',
                            timeText: '2 hari lagi',
                            timeColor: Colors.orangeAccent,
                            imagePath: 'assets/images/food/susu_uht.png',
                          ),
                          const SizedBox(height: 14),

                          Center(
                            child: GestureDetector(
                              onTap: widget.onNavigateToTracker,
                              child: Text(
                                'Lihat Semua',
                                style: AppTextStyles.linkBold.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Impact Score Card
                  Expanded(
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              Icons.eco,
                              size: 90,
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impact Score',
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Minggu ini',
                                style: AppTextStyles.subtitleSmall.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '+120',
                                style: AppTextStyles.heading1.copyWith(
                                  fontSize: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Eco Poin',
                                style: AppTextStyles.subtitleSmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Makanan terselamatkan',
                                style: AppTextStyles.subtitleSmall.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '2.4 kg',
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini Quiz Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MiniQuiz Hari Ini',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.52,
                          child: Text(
                            'Uji pengetahuan gizi kamu dan dapatkan +50 Eco Poin!',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryDark.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quiz dimulai! Jawaban benar +50 Eco Poin!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Mulai Quiz',
                            style: AppTextStyles.buttonSmall.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: Image.asset(
                        'assets/images/food/quiz_illu.png',
                        width: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.quiz_outlined,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroLinearBar({
    required String label,
    required String valueText,
    required String maxText,
    required String percentageText,
    required double ratio,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: valueText,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' $maxText',
                    style: AppTextStyles.subtitleSmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF3F4F6),
                  color: barColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentageText,
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgentItem({
    required String name,
    required String timeText,
    required Color timeColor,
    required String imagePath,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.restaurant,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: timeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
