import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/food_tracker_controller.dart';
import '../../database/db_helper.dart';
import '../../models/food_item_model.dart';
import '../../models/food_log_model.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_circular_progress.dart';
import '../widgets/app_food_image.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/all_catalog_modal.dart';
import 'widgets/food_detail_modal.dart';

class FoodTrackerScreen extends StatefulWidget {
  final int initialTabIndex;

  const FoodTrackerScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FoodTrackerScreen> createState() => _FoodTrackerScreenState();
}

class _FoodTrackerScreenState extends State<FoodTrackerScreen> {
  final _controller = FoodTrackerController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _recentlyAddedFoodNames = {};
  int _unreadNotifsCount = 0;

  List<String> get _tabs => _controller.tabs;
  int get _selectedTabIndex => _controller.selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _controller.setSelectedTab(widget.initialTabIndex);
    _controller.addListener(_onControllerChanged);
    _refreshData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshData() async {
    await _controller.loadData();
    final unread = await DBHelper().getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _unreadNotifsCount = unread;
      });
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _refreshData());
  }

  void _onSearchChanged(String query) {
    _controller.searchCatalog(query);
  }

  void _openAddFoodModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        initialMealType: mealType,
        targetDate: _controller.selectedDate,
        onFoodAdded: _refreshData,
      ),
    );
  }

  void _openAllCatalogModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllCatalogModal(
        currentMealType: mealType,
        targetDate: _controller.selectedDate,
        onFoodAdded: _refreshData,
      ),
    );
  }

  void _openDetailModal(FoodLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodDetailModal(log: log, onLogDeleted: _refreshData),
    );
  }

  void _openFoodScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Scan Barcode & Foto Makanan belum tersedia'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _quickAddFood(FoodItemModel food, String mealType) async {
    if (_recentlyAddedFoodNames.contains(food.name)) return;

    setState(() {
      _recentlyAddedFoodNames.add(food.name);
    });

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final targetDate = _controller.selectedDate;

    final newLog = FoodLogModel(
      foodName: food.name,
      mealType: mealType,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      imagePath: food.imagePath,
      time: timeStr,
      date: AppDateFormatter.formatToday(targetDate),
    );

    final notif = await DBHelper().addFoodLog(newLog);
    await _refreshData();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (notif != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.urgent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        notif.message,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.deepForest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${food.name} Ditambahkan!',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${food.calories} kcal dicatat ke $mealType',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      setState(() {
        _recentlyAddedFoodNames.remove(food.name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            AppTopBar(
              title: 'Food Tracker',
              showBackButton: _selectedTabIndex > 0,
              onBack: () => _controller.setSelectedTab(0),
              unreadNotifications: _unreadNotifsCount,
              onNotificationTap: _openNotifications,
            ),

            // Scrollable Content
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 18,
                        bottom: 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Interactive Date Navigator & Quick Day Switcher
                          _buildDateNavigator(),

                          // Search Bar
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Cari makanan, minuman, atau scan barcode',
                                      border: InputBorder.none,
                                      suffixIcon: _controller.isSearching
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                _onSearchChanged('');
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openFoodScanner,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.mintTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Horizontal Meal Filter Tabs
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _tabs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final tabName = _tabs[index];
                                final isSelected = _selectedTabIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    _controller.setSelectedTab(index);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      tabName,
                                      style: AppTextStyles.bodyMd.copyWith(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textGray,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Display Selected Tab Content
                          if (_controller.isSearching)
                            _buildSearchResultsView()
                          else if (_selectedTabIndex == 0)
                            _buildSummaryTab()
                          else
                            _buildMealCategoryTab(_tabs[_selectedTabIndex]),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIMPLE & INTUITIVE DATE NAVIGATOR ---
  Widget _buildDateNavigator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Day Button (<)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _controller.previousDay(),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 26,
                  color: AppColors.deepForest,
                ),
              ),
            ),
          ),

          // Center Interactive Date Pill (Tap to open DatePicker)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _controller.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.deepForest,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    _controller.setSelectedDate(picked);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.mintTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _controller.dateDisplayLabel,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepForest,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textGray,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Next Day Button (>)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _controller.nextDay(),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: AppColors.deepForest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RINGKASAN TAB ---
  Widget _buildSummaryTab() {
    final totalCals = _controller.totalCalories;
    final totalProtein = _controller.totalProtein;
    final totalCarbs = _controller.totalCarbs;
    final totalFat = _controller.totalFat;
    final totalCholesterol = _controller.totalCholesterol;
    final nutrientWarnings = _controller.warnings;

    final sarapanLogs = _controller.sarapanLogs;
    final makanSiangLogs = _controller.makanSiangLogs;
    final makanMalamLogs = _controller.makanMalamLogs;
    final camilanLogs = _controller.camilanLogs;

    int sumCals(List<FoodLogModel> list) =>
        list.fold(0, (sum, item) => sum + item.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nutrition Summary Main Card (Eco-Tech Modern Refresh)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title + Date & Target Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.isToday
                              ? 'Ringkasan Nutrisi Hari Ini'
                              : 'Ringkasan Nutrisi (${_controller.isYesterday ? 'Kemarin' : AppDateFormatter.formatShortDate(_controller.selectedDate)})',
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 16,
                            color: AppColors.deepForest,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppColors.textGray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppDateFormatter.formatToday(
                                _controller.selectedDate,
                              ),
                              style: AppTextStyles.subtitleSmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '2.000 kcal Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Progress Ring & Percentage Badge
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
                              painter: AppCircularProgressPainter(
                                progress: (totalCals / 2000).clamp(0.0, 1.0),
                                color: totalCals > 2000
                                    ? AppColors.error
                                    : AppColors.primary,
                                bgColor: AppColors.surfaceContainerHigh,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$totalCals',
                                  style: AppTextStyles.heading1.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: totalCals > 2000
                                        ? AppColors.error
                                        : AppColors.deepForest,
                                  ),
                                ),
                                Text(
                                  'kcal tercatat',
                                  style: AppTextStyles.subtitleSmall.copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textGray,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalCals >= 2000
                                      ? 'Tercapai'
                                      : 'Sisa ${(2000 - totalCals).clamp(0, 2000)}',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: totalCals > 2000
                                        ? AppColors.error
                                        : AppColors.ecoGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: totalCals > 2000
                              ? AppColors.error.withValues(alpha: 0.12)
                              : (totalCals == 0
                                    ? AppColors.surfaceContainerLow
                                    : AppColors.primary.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          totalCals == 0
                              ? '0% tercapai'
                              : '${((totalCals / 2000) * 100).toStringAsFixed(1)}% tercapai',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: totalCals > 2000
                                ? AppColors.error
                                : (totalCals == 0
                                      ? AppColors.textGray
                                      : AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Linear Progress Bars for Nutrients
                  Expanded(
                    child: Column(
                      children: [
                        _buildNutrientBar(
                          icon: Icons.egg_alt_outlined,
                          name: 'Protein',
                          valText: '${totalProtein.toInt()} / 65 g',
                          ratio: (totalProtein / 65).clamp(0.0, 1.0),
                          color: totalProtein > 65.0
                              ? AppColors.secondaryContainer
                              : AppColors.seaGreen,
                          iconBgColor: AppColors.seaGreen.withValues(
                            alpha: 0.12,
                          ),
                          isWarning: totalProtein > 65.0,
                        ),
                        _buildNutrientBar(
                          icon: Icons.bakery_dining_outlined,
                          name: 'Karbohidrat',
                          valText: '${totalCarbs.toInt()} / 300 g',
                          ratio: (totalCarbs / 300).clamp(0.0, 1.0),
                          color: totalCarbs > 300
                              ? AppColors.secondaryContainer
                              : AppColors.infoBlue,
                          iconBgColor: AppColors.infoBlue.withValues(
                            alpha: 0.12,
                          ),
                          isWarning: totalCarbs > 300,
                        ),
                        _buildNutrientBar(
                          icon: Icons.water_drop_outlined,
                          name: 'Lemak',
                          valText: '${totalFat.toInt()} / 67 g',
                          ratio: (totalFat / 67).clamp(0.0, 1.0),
                          color: totalFat >= 67.0
                              ? AppColors.error
                              : const Color(0xFFE65100),
                          iconBgColor:
                              (totalFat >= 67.0
                                      ? AppColors.error
                                      : const Color(0xFFE65100))
                                  .withValues(alpha: 0.12),
                          isWarning: totalFat >= 67.0,
                        ),
                        _buildNutrientBar(
                          icon: Icons.favorite_outline,
                          name: 'Kolesterol',
                          valText: '${totalCholesterol.toInt()} / 300 mg',
                          ratio: (totalCholesterol / 300).clamp(0.0, 1.0),
                          color: totalCholesterol > 300
                              ? AppColors.error
                              : const Color(0xFFD97706),
                          iconBgColor: const Color(
                            0xFFD97706,
                          ).withValues(alpha: 0.12),
                          isWarning: totalCholesterol > 300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Warning Alert Cards Section
        if (nutrientWarnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...nutrientWarnings.map(
            (w) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (w['color'] as Color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (w['color'] as Color).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (w['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      w['icon'] as IconData,
                      color: w['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w['title'] as String,
                          style: AppTextStyles.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: w['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          w['message'] as String,
                          style: AppTextStyles.subtitleSmall.copyWith(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // "Makanan Hari Ini" Meal Summary Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _controller.isToday
                  ? 'Makanan Hari Ini'
                  : 'Makanan (${_controller.isYesterday ? 'Kemarin' : AppDateFormatter.formatShortDate(_controller.selectedDate)})',
              style: AppTextStyles.heading2.copyWith(fontSize: 16),
            ),
            if (!_controller.isToday)
              GestureDetector(
                onTap: () => _controller.setToday(),
                child: Text(
                  'Lihat Hari Ini',
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_controller.allLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_outlined,
                    color: AppColors.textGraySoft,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _controller.isToday
                      ? 'Belum Ada Santapan Hari Ini'
                      : 'Tidak Ada Catatan Makanan',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 15,
                    color: AppColors.deepForest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.isToday
                      ? 'Mulai hari sehatmu dengan mencatat sarapan atau santapan pertama!'
                      : 'Tidak ada makanan yang dicatat pada ${AppDateFormatter.formatToday(_controller.selectedDate)}.',
                  style: AppTextStyles.subtitleSmall.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddFoodModal('Sarapan'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Catat Makanan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
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
          _buildMealCategoryCard(
            title: 'Sarapan',
            countText: '${sarapanLogs.length} makanan',
            calsText: '${sumCals(sarapanLogs)} kcal',
            icon: Icons.wb_twilight_rounded,
            iconColor: AppColors.seaGreen,
            onTap: () => _controller.setSelectedTab(1),
          ),
          const SizedBox(height: 10),

          _buildMealCategoryCard(
            title: 'Makan Siang',
            countText: '${makanSiangLogs.length} makanan',
            calsText: '${sumCals(makanSiangLogs)} kcal',
            icon: Icons.light_mode_rounded,
            iconColor: AppColors.secondaryContainer,
            onTap: () => _controller.setSelectedTab(2),
          ),
          const SizedBox(height: 10),

          _buildMealCategoryCard(
            title: 'Makan Malam',
            countText: '${makanMalamLogs.length} makanan',
            calsText: '${sumCals(makanMalamLogs)} kcal',
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.urgent,
            onTap: () => _controller.setSelectedTab(3),
          ),
          const SizedBox(height: 10),

          _buildMealCategoryCard(
            title: 'Camilan',
            countText: '${camilanLogs.length} makanan',
            calsText: '${sumCals(camilanLogs)} kcal',
            icon: Icons.tapas_rounded,
            iconColor: AppColors.infoBlue,
            onTap: () => _controller.setSelectedTab(4),
          ),
        ],
      ],
    );
  }

  // --- MEAL CATEGORY TAB (Sarapan, Makan Siang, Makan Malam, Camilan) ---
  Widget _buildMealCategoryTab(String mealType) {
    final logs = _controller.allLogs
        .where((l) => l.mealType == mealType)
        .toList();
    final totalCals = logs.fold(0, (sum, item) => sum + item.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType,
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateFormatter.formatToday(_controller.selectedDate),
                  style: AppTextStyles.subtitleSmall,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Total', style: AppTextStyles.subtitleSmall),
                Text(
                  '$totalCals kcal',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List of Logged Food Cards
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.no_meals_outlined,
                  size: 44,
                  color: AppColors.textGray,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada makanan dicatat untuk $mealType',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildFoodLogCard(log);
            },
          ),
        const SizedBox(height: 16),

        // "Tambah Makanan" Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            onPressed: () => _openAddFoodModal(mealType),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Tambah Makanan',
              style: AppTextStyles.button.copyWith(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tips Sehat Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Sehat',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 13,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTipForMeal(mealType),
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.primaryDark.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Terakhir Ditambahkan Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Terakhir Ditambahkan',
              style: AppTextStyles.heading2.copyWith(fontSize: 16),
            ),
            TextButton(
              onPressed: () => _openAllCatalogModal(mealType),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.linkBold.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick add list from catalog
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controller.recentCatalog.take(3).length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final food = _controller.recentCatalog[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      food.imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.fastfood,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${food.calories} kcal · Baru saja',
                          style: AppTextStyles.subtitleSmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${food.calories}',
                    style: AppTextStyles.heading2.copyWith(fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final isAdded = _recentlyAddedFoodNames.contains(food.name);
                      return GestureDetector(
                        onTap: isAdded ? null : () => _quickAddFood(food, mealType),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isAdded
                                ? AppColors.mintTint
                                : AppColors.infoContainer,
                            shape: BoxShape.circle,
                            border: isAdded
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isAdded ? Icons.check_rounded : Icons.add,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFoodLogCard(FoodLogModel log) {
    return GestureDetector(
      onTap: () => _openDetailModal(log),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                log.imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.foodName,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(log.time, style: AppTextStyles.subtitleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Protein ${log.protein} g · Karbo ${log.carbs} g · Lemak ${log.fat} g',
                    style: AppTextStyles.subtitleSmall.copyWith(
                      fontSize: 10.5,
                      color: AppColors.textGraySoft,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${log.calories}',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text('kcal', style: AppTextStyles.subtitleSmall),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCategoryCard({
    required String title,
    required String countText,
    required String calsText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final hasCals = !calsText.startsWith('0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepForest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countText,
                      style: AppTextStyles.subtitleSmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: hasCals
                        ? AppColors.mintTint
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: hasCals
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    calsText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: hasCals ? AppColors.primary : AppColors.textGray,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGray,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBar({
    required IconData icon,
    required String name,
    required String valText,
    required double ratio,
    required Color color,
    required Color iconBgColor,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 11.5, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForest,
                    ),
                  ),
                  if (isWarning) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
              Text(
                valText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isWarning ? AppColors.error : AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTipForMeal(String mealType) {
    switch (mealType) {
      case 'Sarapan':
        return 'Awali hari dengan sarapan yang mengandung karbohidrat dan protein agar energi lebih terjaga.';
      case 'Makan Siang':
        return 'Lengkapi makan siang dengan sumber karbohidrat, protein, dan sayuran agar lebih seimbang.';
      case 'Makan Malam':
        return 'Padukan sumber protein dengan sayuran untuk membuat makan malam lebih seimbang.';
      case 'Camilan':
        return 'Pilih camilan yang lebih mengenyangkan dan tetap perhatikan jumlah porsinya.';
      default:
        return 'Jaga pola makan seimbang setiap hari.';
    }
  }

  Widget _buildSearchResultsView() {
    if (_controller.searchResults.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Tidak ada makanan cocok dengan "${_searchController.text}"',
            style: AppTextStyles.subtitle,
          ),
        ),
      );
    }

    final currentMealType = _selectedTabIndex > 0
        ? _tabs[_selectedTabIndex]
        : 'Makan Siang';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hasil Pencarian (${_controller.searchResults.length})',
                style: AppTextStyles.heading2.copyWith(fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _controller.searchResults.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final food = _controller.searchResults[index];
              final isAdded = _recentlyAddedFoodNames.contains(food.name);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: isAdded
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    AppFoodImage(
                      imagePath: food.imagePath,
                      width: 50,
                      height: 50,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.name,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${food.calories} kcal · ${food.category}',
                            style: AppTextStyles.subtitleSmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdded
                              ? AppColors.mintTint
                              : AppColors.primary,
                          elevation: isAdded ? 0 : 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isAdded
                                ? const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: isAdded
                            ? null
                            : () => _quickAddFood(food, currentMealType),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdded
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 16,
                              color: isAdded
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAdded ? 'Tercatat' : 'Tambah',
                              style: AppTextStyles.buttonSmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isAdded
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
