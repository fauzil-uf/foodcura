import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/dashboard_controller.dart';
import '../../database/db_helper.dart';
import '../../models/pantry_item_model.dart';
import '../food_tracker/widgets/add_food_modal.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_circular_progress.dart';
import '../widgets/app_food_image.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/eco_impact_modal.dart';
import 'widgets/quiz_modal.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToTracker;
  final VoidCallback? onNavigateToPantry;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTracker,
    this.onNavigateToPantry,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _controller = DashboardController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    _controller.addListener(_onControllerChanged);
    _controller.loadDashboardData();
    NotificationNotifier.instance.addListener(_onNotifChanged);
    NotificationNotifier.instance.refresh();
    EcoPointsNotifier.instance.addListener(_onEcoPointsChanged);
    EcoPointsNotifier.instance.init();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    EcoPointsNotifier.instance.removeListener(_onEcoPointsChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onNotifChanged() {
    if (mounted) _controller.loadDashboardData();
  }

  void _onEcoPointsChanged() {
    if (mounted) _controller.loadDashboardData();
  }

  Future<void> _fetchSummaryFromDB() async {
    await _controller.loadDashboardData();
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _fetchSummaryFromDB());
  }

  void _startQuiz() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuizModal(),
    ).then((_) => _fetchSummaryFromDB());
  }

  void _openAddFoodModal({String mealType = 'Makan Siang'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        initialMealType: mealType,
        onFoodAdded: _fetchSummaryFromDB,
      ),
    );
  }

  void _openEcoImpactModal(PantryItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcoImpactModal(
        item: item,
        impactNarrative:
            'Kamu berhasil menyelamatkan ${item.name}! Tindakan ini mencegah emisi karbon CO2e dan menghemat pengeluaran dapur.',
        earnedPoints: 10,
        onDismiss: _fetchSummaryFromDB,
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.user;
    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim().split(' ').first
        : 'Sobat';
    final greeting = _getTimeGreeting();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // 1. PINNED TOP APP BAR
              AppTopBar(
                showBrandLogo: true,
                unreadNotifications: _controller.unreadNotifications,
                onNotificationTap: _openNotifications,
              ),

              // 2. SCROLLABLE BODY CONTENT
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 18,
                    bottom: 110,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sapaan & Live Status Badges
                      _buildGreetingAndBadges(userName, greeting),
                      const SizedBox(height: 16),

                      // 2. HERO HEALTH & NUTRITION HUB CARD
                      _buildHeroHealthHubCard(),
                      const SizedBox(height: 20),

                      // 3. AI NUTRITION COACH CARD
                      _buildAiNutritionCoachCard(),
                      const SizedBox(height: 20),

                      // 5. BENTO GRID: EXPIRY RADAR & ECO IMPACT
                      _buildBentoSection(),
                      const SizedBox(height: 20),

                      // 6. LINIMASA SANTAPAN HARI INI (TODAY'S MEAL FEED)
                      _buildTodayMealsSection(),
                      const SizedBox(height: 20),

                      // 7. BANNER TANTANGAN MINIQUIZ
                      _buildMiniQuizBanner(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GREETING & LIVE BADGES ────────────────────────────────────────────────
  Widget _buildGreetingAndBadges(String userName, String greeting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // Personalized Greeting & Subtitle
        Text(
          '$greeting, $userName! 👋',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepForest,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Siap jaga nutrisi & kurangi food waste hari ini?',
          style: AppTextStyles.subtitleSmall.copyWith(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
        const SizedBox(height: 12),
        // Live Status Badges Row
        Row(
          children: [
            // Streak Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${_controller.streak} Hari Streak',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Eco Points Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mintTint,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_controller.ecoPoints} Eco Poin',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Date Badge
            Text(
              AppDateFormatter.formatToday(),
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 2. HERO HEALTH & NUTRITION HUB CARD ───────────────────────────────────
  Widget _buildHeroHealthHubCard() {
    final totalCals = _controller.totalCalories;
    final targetCals = _controller.targetCalories;
    final remainingCals = targetCals - totalCals;
    final ratio = _controller.caloriesRatio;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143E24), Color(0xFF0F301B), Color(0xFF0A2213)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143E24).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ecoGreen.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Sub-header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFF81C784),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pusat Asupan Nutrisi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: widget.onNavigateToTracker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Analisis Detail',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Main Calorie Ring + Stats Info
                Row(
                  children: [
                    // Calorie Circular Progress Ring
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(108, 108),
                            painter: AppCircularProgressPainter(
                              progress: ratio,
                              color: totalCals > targetCals
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF4CAF50),
                              bgColor: Colors.white.withValues(alpha: 0.15),
                              strokeWidth: 9.0,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$totalCals',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'kcal',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Target & Remaining Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: totalCals > targetCals
                                  ? const Color(
                                      0xFFFF5252,
                                    ).withValues(alpha: 0.25)
                                  : AppColors.ecoGreen.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              totalCals > targetCals
                                  ? '⚠️ Melebihi Target'
                                  : '✨ ${remainingCals > 0 ? '$remainingCals kcal tersisa' : 'Target Tercapai'}',
                              style: TextStyle(
                                color: totalCals > targetCals
                                    ? const Color(0xFFFF8A80)
                                    : const Color(0xFFA5D6A7),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Target Harian: $targetCals kcal',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kebutuhan kalori standar Kemenkes RI untuk aktivitas harian normal.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4 Bento Macro Mini Cards
                Row(
                  children: [
                    _buildMacroPillCard(
                      label: 'Protein',
                      current: _controller.proteinGrams,
                      max: _controller.proteinMax,
                      unit: 'g',
                      barColor: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 8),
                    _buildMacroPillCard(
                      label: 'Karbohidrat',
                      current: _controller.carbsGrams,
                      max: _controller.carbsMax,
                      unit: 'g',
                      barColor: const Color(0xFF42A5F5),
                    ),
                    const SizedBox(width: 8),
                    _buildMacroPillCard(
                      label: 'Lemak',
                      current: _controller.lemakGrams,
                      max: _controller.lemakMax,
                      unit: 'g',
                      barColor:
                          _controller.lemakGrams >= _controller.lemakMax
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 8),
                    _buildMacroPillCard(
                      label: 'Kolesterol',
                      current: _controller.kolesterolMg,
                      max: _controller.kolesterolMax,
                      unit: 'mg',
                      barColor:
                          _controller.kolesterolMg > _controller.kolesterolMax
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFBA68C8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPillCard({
    required String label,
    required double current,
    required double max,
    required String unit,
    required Color barColor,
  }) {
    final ratio = (current / max).clamp(0.0, 1.0);
    final isExceeded = current > max;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExceeded
                ? const Color(0xFFFF5252).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${current.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. AI NUTRITION COACH CARD ────────────────────────────────────────────
  Widget _buildAiNutritionCoachCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Nutrition Coach',
                            style: AppTextStyles.heading2.copyWith(
                              fontSize: 15,
                              color: AppColors.deepForest,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Gemini',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rekomendasi & evaluasi menu cerdas',
                        style: AppTextStyles.subtitleSmall.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Perbarui Saran',
                icon: _controller.isAiAdviceLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                onPressed: _controller.isAiAdviceLoading
                    ? null
                    : () => _controller.fetchAiNutritionAdvice(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_controller.isAiAdviceLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI sedang menganalisis pola makanmu...',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            )
          else if (_controller.aiNutritionAdvice != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                _controller.aiNutritionAdvice!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.deepForest,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _controller.fetchAiNutritionAdvice(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ketuk untuk dapatkan saran gizi personal AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 5. BENTO GRID: EXPIRY RADAR & ECO IMPACT ──────────────────────────────
  Widget _buildBentoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expiry Radar Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
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
                          'Radar Expiry',
                          style: AppTextStyles.heading2.copyWith(fontSize: 14),
                        ),
                        Text(
                          'Stok rawan basi',
                          style: AppTextStyles.subtitleSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _controller.urgentPantryItems.isNotEmpty
                            ? const Color(0xFFFFEBEE)
                            : AppColors.mintTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _controller.urgentPantryItems.isNotEmpty
                            ? '${_controller.urgentPantryItems.length} Urgent'
                            : 'Aman',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _controller.urgentPantryItems.isNotEmpty
                              ? Colors.redAccent
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_controller.urgentPantryItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.ecoGreen,
                            size: 28,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Semua stok aman!',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ecoGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ..._controller.urgentPantryItems.take(2).map((item) {
                    final days = item.daysUntilExpiry;
                    final timeText = days <= 0
                        ? (days == 0 ? 'Hari ini!' : 'Lewat ${-days}h')
                        : '$days hari lagi';
                    final timeColor = days <= 1
                        ? Colors.redAccent
                        : Colors.orangeAccent;

                    return GestureDetector(
                      onTap: () => _openEcoImpactModal(item),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              AppFoodImage(
                                imagePath: item.imageUrl ?? '',
                                width: 34,
                                height: 34,
                                borderRadius: 8,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      timeText,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: timeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.eco_rounded,
                                size: 16,
                                color: AppColors.ecoGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

                Center(
                  child: GestureDetector(
                    onTap:
                        widget.onNavigateToPantry ?? widget.onNavigateToTracker,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Buka Pantry ➜',
                        style: AppTextStyles.linkBold.copyWith(
                          fontSize: 11.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Eco Impact Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
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
                          'Dampak Eco',
                          style: AppTextStyles.heading2.copyWith(fontSize: 14),
                        ),
                        Text(
                          'Penyelamatan pangan',
                          style: AppTextStyles.subtitleSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rescued Stats
                Text(
                  '+${_controller.ecoPoints}',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Total Poin Hijau',
                  style: AppTextStyles.subtitleSmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bahan Selamat',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textGray,
                          ),
                        ),
                        Text(
                          '${_controller.rescuedKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepForest,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Hemat Finansial',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textGray,
                          ),
                        ),
                        Text(
                          _controller.savedMoney > 0
                              ? 'Rp ${_controller.savedMoney.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}'
                              : 'Rp 0',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 6. TODAY'S MEAL FEED ──────────────────────────────────────────────────
  Widget _buildTodayMealsSection() {
    final todayLogs = _controller.todayLogs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.restaurant_menu_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Santapan Hari Ini',
                    style: AppTextStyles.heading2.copyWith(fontSize: 15),
                  ),
                ],
              ),
              if (todayLogs.isNotEmpty)
                GestureDetector(
                  onTap: widget.onNavigateToTracker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: AppTextStyles.linkBold.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (todayLogs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 36,
                    color: AppColors.textGray.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada santapan yang dicatat hari ini',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openAddFoodModal(mealType: 'Sarapan'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Catat Sarapan Pertama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayLogs.length > 3 ? 3 : todayLogs.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final log = todayLogs[index];
                return Row(
                  children: [
                    AppFoodImage(
                      imagePath: log.imagePath,
                      width: 44,
                      height: 44,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.foodName,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepForest,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${log.mealType} · ${log.time}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${log.calories} kcal',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAddFoodModal(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tambah Makanan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.mintTint.withValues(alpha: 0.4),
                  side: const BorderSide(color: AppColors.borderSoft),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 7. MINI QUIZ BANNER ───────────────────────────────────────────────────
  Widget _buildMiniQuizBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+50 ECO POIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tantangan Gizi Hari Ini',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 15,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Uji pengetahuan gizi dan dapatkan poin bonus.',
                  style: AppTextStyles.subtitleSmall.copyWith(
                    fontSize: 11.5,
                    color: AppColors.deepForest.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Kuis Sekarang',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF57F17),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}
