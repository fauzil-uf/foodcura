import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_date_formatter.dart';
import '../constants/app_typography.dart';
import '../database/db_helper.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import 'notification_screen.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/all_catalog_modal.dart';
import 'widgets/app_food_image.dart';
import 'widgets/food_detail_modal.dart';

class FoodTrackerScreen extends StatefulWidget {
  final int initialTabIndex;

  const FoodTrackerScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FoodTrackerScreen> createState() => _FoodTrackerScreenState();
}

class _FoodTrackerScreenState extends State<FoodTrackerScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<FoodLogModel> _allLogs = [];
  List<FoodItemModel> _fullCatalog = [];
  List<FoodItemModel> _recentCatalog = [];
  List<FoodItemModel> _searchResults = [];
  bool _isSearching = false;
  bool _loading = true;
  int _unreadNotifsCount = 0;

  final List<String> _tabs = [
    'Ringkasan',
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    final logs = await DBHelper().getFoodLogs(
      date: AppDateFormatter.formatToday(),
    );
    final catalog = await DBHelper().getFoodCatalog();
    final recentAdded = await DBHelper().getRecentAddedFoods(limit: 5);
    final unread = await DBHelper().getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _fullCatalog = catalog;
        _recentCatalog = recentAdded;
        _unreadNotifsCount = unread;
        _loading = false;
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
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = _fullCatalog
            .where(
              (item) =>
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.category.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      });
    }
  }

  void _openAddFoodModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddFoodModal(initialMealType: mealType, onFoodAdded: _refreshData),
    );
  }

  void _openAllCatalogModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AllCatalogModal(currentMealType: mealType, onFoodAdded: _refreshData),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (_selectedTabIndex > 0) {
                        setState(() => _selectedTabIndex = 0);
                      }
                    },
                  ),
                  Text(
                    'Food Tracker',
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        if (_unreadNotifsCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 15,
                                minHeight: 15,
                              ),
                              child: Text(
                                _unreadNotifsCount > 9 ? '9+' : '$_unreadNotifsCount',
                                style: const TextStyle(
                                  fontSize: 8,
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
            ),

            // Scrollable Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                  color: Colors.black.withOpacity(0.03),
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
                                      suffixIcon: _isSearching
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
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.textGraySoft,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isSearching) _buildSearchResultsView(),

                          // Horizontal Meal Filter Tabs
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _tabs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final tabName = _tabs[index];
                                final isSelected = _selectedTabIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTabIndex = index;
                                    });
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
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      tabName,
                                      style: TextStyle(
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
                          if (_selectedTabIndex == 0)
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

  // --- RINGKASAN TAB ---
  Widget _buildSummaryTab() {
    int totalCals = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var l in _allLogs) {
      totalCals += l.calories;
      totalProtein += l.protein;
      totalCarbs += l.carbs;
      totalFat += l.fat;
    }

    double totalCholesterol = (totalFat * 4.5 + totalProtein * 3.5);
    if (totalCholesterol <= 0) totalCholesterol = 180.0;

    final List<Map<String, dynamic>> nutrientWarnings = [];

    // 1. Lemak Jenuh
    if (totalFat >= 25.0) {
      nutrientWarnings.add({
        'title': 'Peringatan Lemak Jenuh Tinggi!',
        'message':
            'Asupan Lemak Jenuh hari ini (${totalFat.toStringAsFixed(1)}g / 25g) telah melebihi batas harian. Batasi gorengan atau olahan bersantan.',
        'color': AppColors.error,
        'icon': Icons.warning_amber_rounded,
      });
    } else if (totalFat >= 20.0) {
      nutrientWarnings.add({
        'title': 'Perhatian Lemak Jenuh',
        'message':
            'Asupan Lemak Jenuh (${totalFat.toStringAsFixed(1)}g / 25g) mendekati batas harian disarankan.',
        'color': const Color(0xFFFD9C40),
        'icon': Icons.info_outline_rounded,
      });
    }

    // 2. Kolesterol
    if (totalCholesterol >= 300.0) {
      nutrientWarnings.add({
        'title': 'Peringatan Kolesterol Tinggi!',
        'message':
            'Estimasi Kolesterol hari ini (${totalCholesterol.toInt()} mg / 300 mg) telah melebihi batas harian yang disarankan.',
        'color': AppColors.error,
        'icon': Icons.favorite_rounded,
      });
    }

    // 3. Kalori
    if (totalCals > 2000) {
      nutrientWarnings.add({
        'title': 'Peringatan Kalori Berlebih!',
        'message':
            'Total asupan kalori ($totalCals kcal / 2000 kcal) telah melebihi target harian Anda.',
        'color': AppColors.error,
        'icon': Icons.local_fire_department_rounded,
      });
    }

    // 4. Karbohidrat
    if (totalCarbs > 300.0) {
      nutrientWarnings.add({
        'title': 'Peringatan Karbohidrat Tinggi!',
        'message':
            'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / 300g) telah melebihi rekomendasi harian.',
        'color': const Color(0xFFFD9C40),
        'icon': Icons.bakery_dining_rounded,
      });
    }

    // 5. Protein
    if (totalProtein > 105.0) {
      nutrientWarnings.add({
        'title': 'Asupan Protein Sangat Tinggi',
        'message':
            'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / 65g) telah jauh melampaui kebutuhan harian.',
        'color': const Color(0xFF3B82F6),
        'icon': Icons.fitness_center_rounded,
      });
    }

    final sarapanLogs = _allLogs.where((l) => l.mealType == 'Sarapan').toList();
    final makanSiangLogs =
        _allLogs.where((l) => l.mealType == 'Makan Siang').toList();
    final makanMalamLogs =
        _allLogs.where((l) => l.mealType == 'Makan Malam').toList();
    final camilanLogs = _allLogs.where((l) => l.mealType == 'Camilan').toList();

    int sumCals(List<FoodLogModel> list) =>
        list.fold(0, (sum, item) => sum + item.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nutrition Summary Main Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Nutrisi Hari Ini',
                style: AppTextStyles.heading2.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                AppDateFormatter.formatToday(),
                style: AppTextStyles.subtitleSmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Circular Progress Ring & Percentage Badge
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 105,
                        height: 105,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(105, 105),
                              painter: _CircularProgressPainter(
                                progress: (totalCals / 2000).clamp(0.0, 1.0),
                                color: totalCals > 2000
                                    ? AppColors.error
                                    : AppColors.primaryLight,
                                bgColor: const Color(0xFFE9E8E2),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$totalCals',
                                  style: AppTextStyles.heading1.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: totalCals > 2000
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '/ 2.000\nkcal',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.subtitleSmall.copyWith(
                                    fontSize: 9,
                                    height: 1.1,
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
                          color: totalCals > 2000
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.infoContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${((totalCals / 2000) * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: totalCals > 2000
                                ? AppColors.error
                                : AppColors.primary,
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
                          color: const Color(0xFF2E8B57),
                        ),
                        const SizedBox(height: 8),
                        _buildNutrientBar(
                          icon: Icons.bakery_dining_outlined,
                          name: 'Karbohidrat',
                          valText: '${totalCarbs.toInt()} / 300 g',
                          ratio: (totalCarbs / 300).clamp(0.0, 1.0),
                          color: totalCarbs > 300
                              ? const Color(0xFFFD9C40)
                              : AppColors.primaryLight,
                          isWarning: totalCarbs > 300,
                        ),
                        const SizedBox(height: 8),
                        _buildNutrientBar(
                          icon: Icons.water_drop_outlined,
                          name: 'Lemak Jenuh',
                          valText: '${totalFat.toInt()} / 25 g',
                          ratio: (totalFat / 25).clamp(0.0, 1.0),
                          color: totalFat >= 25.0
                              ? AppColors.error
                              : const Color(0xFFFD9C40),
                          isWarning: totalFat >= 25.0,
                        ),
                        const SizedBox(height: 8),
                        _buildNutrientBar(
                          icon: Icons.favorite_outline,
                          name: 'Kolesterol',
                          valText: '${totalCholesterol.toInt()} / 300 mg',
                          ratio: (totalCholesterol / 300).clamp(0.0, 1.0),
                          color: totalCholesterol > 300
                              ? AppColors.error
                              : const Color(0xFFEAB308),
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
                color: (w['color'] as Color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (w['color'] as Color).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (w['color'] as Color).withOpacity(0.15),
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
        Text(
          'Makanan Hari Ini',
          style: AppTextStyles.heading2.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),

        _buildMealCategoryCard(
          title: 'Sarapan',
          countText: '${sarapanLogs.length} makanan',
          calsText: '${sumCals(sarapanLogs)} kcal',
          icon: Icons.wb_twilight_rounded,
          iconColor: const Color(0xFF2E8B57),
          onTap: () => setState(() => _selectedTabIndex = 1),
        ),
        const SizedBox(height: 10),

        _buildMealCategoryCard(
          title: 'Makan Siang',
          countText: '${makanSiangLogs.length} makanan',
          calsText: '${sumCals(makanSiangLogs)} kcal',
          icon: Icons.light_mode_rounded,
          iconColor: const Color(0xFFFD9C40),
          onTap: () => setState(() => _selectedTabIndex = 2),
        ),
        const SizedBox(height: 10),

        _buildMealCategoryCard(
          title: 'Makan Malam',
          countText: '${makanMalamLogs.length} makanan',
          calsText: '${sumCals(makanMalamLogs)} kcal',
          icon: Icons.dark_mode_rounded,
          iconColor: const Color(0xFFD95338),
          onTap: () => setState(() => _selectedTabIndex = 3),
        ),
        const SizedBox(height: 10),

        _buildMealCategoryCard(
          title: 'Camilan',
          countText: '${camilanLogs.length} makanan',
          calsText: '${sumCals(camilanLogs)} kcal',
          icon: Icons.tapas_rounded,
          iconColor: const Color(0xFF2196F3),
          onTap: () => setState(() => _selectedTabIndex = 4),
        ),
      ],
    );
  }

  // --- MEAL CATEGORY TAB (Sarapan, Makan Siang, Makan Malam, Camilan) ---
  Widget _buildMealCategoryTab(String mealType) {
    final logs = _allLogs.where((l) => l.mealType == mealType).toList();
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
                  AppDateFormatter.formatToday(),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                        color: AppColors.primaryDark.withOpacity(0.85),
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
          itemCount: _recentCatalog.take(3).length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final food = _recentCatalog[index];
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
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final timeStr =
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      final newLog = FoodLogModel(
                        foodName: food.name,
                        mealType: mealType,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fat: food.fat,
                        imagePath: food.imagePath,
                        time: timeStr,
                        date: AppDateFormatter.formatToday(),
                      );
                      await DBHelper().addFoodLog(newLog);
                      _refreshData();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.infoContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
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
              color: Colors.black.withOpacity(0.03),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.infoContainer,
                    shape: BoxShape.circle,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(countText, style: AppTextStyles.subtitleSmall),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  calsText,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textGray,
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
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 14,
                    color: isWarning ? AppColors.error : AppColors.primaryDark),
                const SizedBox(width: 4),
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    fontWeight: isWarning ? FontWeight.w700 : FontWeight.w600,
                    color: isWarning ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                if (isWarning) ...[
                  const SizedBox(width: 3),
                  const Icon(Icons.warning_amber_rounded,
                      size: 12, color: AppColors.error),
                ],
              ],
            ),
            Text(
              valText,
              style: AppTextStyles.subtitleSmall.copyWith(
                fontSize: 10,
                color: isWarning ? AppColors.error : null,
                fontWeight: isWarning ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: const Color(0xFFE9E8E2),
            color: color,
          ),
        ),
      ],
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
    if (_searchResults.isEmpty) {
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

    final currentMealType =
        _selectedTabIndex > 0 ? _tabs[_selectedTabIndex] : 'Makan Siang';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                'Hasil Pencarian (${_searchResults.length})',
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
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final food = _searchResults[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        final newLog = FoodLogModel(
                          foodName: food.name,
                          mealType: currentMealType,
                          calories: food.calories,
                          protein: food.protein,
                          carbs: food.carbs,
                          fat: food.fat,
                          imagePath: food.imagePath,
                          time: AppDateFormatter.formatTime(),
                          date: AppDateFormatter.formatToday(),
                        );
                        await DBHelper().addFoodLog(newLog);
                        _searchController.clear();
                        _onSearchChanged('');
                        _refreshData();
                      },
                      child: const Text(
                        '+ Tambah',
                        style: TextStyle(fontSize: 12, color: Colors.white),
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
    final radius = (size.width - 12) / 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 9
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
