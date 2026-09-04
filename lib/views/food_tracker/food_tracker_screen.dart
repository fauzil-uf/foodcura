import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../controllers/food_tracker_controller.dart';
import '../../models/food_item_model.dart';
import '../../models/food_log_model.dart';
import '../../services/app_notifiers.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/all_catalog_modal.dart';
import 'widgets/food_detail_modal.dart';
import 'widgets/food_meal_tab.dart';
import 'widgets/food_search_results.dart';
import 'widgets/food_summary_card.dart';
import 'widgets/food_tracker_header.dart';

// Layar pelacak nutrisi & log makanan harian
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

  List<String> get _tabs => _controller.tabs;
  int get _selectedTabIndex => _controller.selectedTabIndex;

  @override
  void initState() {
    super.initState();
    // Pasang tab awal dan sinkronkan listener event global
    _controller.setSelectedTab(widget.initialTabIndex);
    _controller.addListener(_onControllerChanged);
    PantryUpdateNotifier.instance.addListener(_onPantryChanged);
    NotificationNotifier.instance.addListener(_onNotifChanged);
    _refreshData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    PantryUpdateNotifier.instance.removeListener(_onPantryChanged);
    NotificationNotifier.instance.removeListener(_onNotifChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Update tampilan saat state controller berubah
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // Muat ulang daftar makanan jika ada bahan pantry yang baru dimasak
  void _onPantryChanged() {
    if (mounted) _controller.loadData();
  }

  // Refresh badge notifikasi unread jika ada notifikasi baru
  void _onNotifChanged() {
    if (mounted) _controller.refreshUnreadCount();
  }

  // Ambil data log makanan untuk tanggal yang sedang dipilih
  Future<void> _refreshData() async {
    await _controller.loadData();
  }

  // Buka layar notifikasi
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _controller.refreshUnreadCount());
  }

  // Filter katalog makanan berdasarkan query input pencarian
  void _onSearchChanged(String query) {
    _controller.searchCatalog(query);
  }

  // Buka modal input catat makanan baru untuk jenis makan tertentu
  void _openAddFoodModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        initialMealType: mealType,
        targetDate: _controller.selectedDate,
        controller: _controller,
        recentFoods: _controller.recentCatalog,
      ),
    );
  }

  // Modal telusuri semua katalog makanan
  void _openAllCatalogModal(String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllCatalogModal(
        currentMealType: mealType,
        targetDate: _controller.selectedDate,
        controller: _controller,
      ),
    );
  }

  // Modal detail & edit makanan
  void _openDetailModal(FoodLogModel log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodDetailModal(log: log, controller: _controller),
    );
  }

  // Placeholder scanner makanan
  void _openFoodScanner() {
    AppSnackBar.showInfo(
      context,
      'Fitur Scan Barcode & Foto Makanan segera hadir!',
    );
  }

  // Quick add makanan (dengan anti-spam)
  Future<void> _quickAddFood(FoodItemModel food, String mealType) async {
    if (_recentlyAddedFoodNames.contains(food.name)) return;

    setState(() {
      _recentlyAddedFoodNames.add(food.name);
    });

    final targetDate = _controller.selectedDate;

    final newLog = FoodLogModel(
      foodName: food.name,
      mealType: mealType,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      cholesterol: food.cholesterol,
      imagePath: food.imagePath,
      time: AppDateFormatter.formatTime(),
      date: AppDateFormatter.formatToday(targetDate),
    );

    // addFoodLog sudah memanggil loadData() secara internal.
    final notif = await _controller.addFoodLog(newLog);

    if (mounted) {
      if (notif != null) {
        AppSnackBar.showWarning(
          context,
          title: notif.title,
          message: notif.message,
        );
      } else {
        AppSnackBar.showSuccess(
          context,
          '${food.name} Ditambahkan!',
          subtitle: '${food.calories} kcal dicatat ke $mealType',
        );
      }
    }

    // Buka kembali kunci tombol setelah 1,6 detik untuk input berikutnya.
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
            AppTopBar(
              title: 'Food Tracker',
              showBackButton: _selectedTabIndex > 0,
              onBack: () => _controller.setSelectedTab(0),
              unreadNotifications: _controller.unreadNotifications,
              onNotificationTap: _openNotifications,
            ),

            Expanded(
              child: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _controller.loadData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 18,
                          bottom: 110,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FoodTrackerHeader(
                              tabs: _tabs,
                              selectedTabIndex: _selectedTabIndex,
                              selectedDate: _controller.selectedDate,
                              dateDisplayLabel: _controller.dateDisplayLabel,
                              searchController: _searchController,
                              isSearching: _controller.isSearching,
                              onBack: () => _controller.setSelectedTab(0),
                              onDateTap: () async {
                                final now = DateTime.now();
                                final today =
                                    DateTime(now.year, now.month, now.day);
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _controller.selectedDate
                                          .isAfter(today)
                                      ? today
                                      : _controller.selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: today,
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
                              onPreviousDay: () => _controller.previousDay(),
                              onNextDay: () => _controller.nextDay(),
                              canGoNextDay: _controller.canGoNextDay,
                              onSearchChanged: _onSearchChanged,
                              onFoodScannerTap: _openFoodScanner,
                              onTabChanged: (index) =>
                                  _controller.setSelectedTab(index),
                            ),
                            const SizedBox(height: 20),

                            if (_controller.isSearching)
                              FoodSearchResults(
                                searchQuery: _searchController.text,
                                searchResults: _controller.searchResults,
                                currentMealType: _selectedTabIndex > 0
                                    ? _tabs[_selectedTabIndex]
                                    : 'Makan Siang',
                                recentlyAddedFoodNames: _recentlyAddedFoodNames,
                                onClear: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                onQuickAdd: _quickAddFood,
                              )
                            else if (_selectedTabIndex == 0)
                              FoodSummaryCard(
                                controller: _controller,
                                nutrientWarnings: _controller.warnings,
                                onAddFood: _openAddFoodModal,
                                onOpenMealTab: (index) =>
                                    _controller.setSelectedTab(index),
                              )
                            else
                              FoodMealTab(
                                mealType: _tabs[_selectedTabIndex],
                                logs: _controller.filteredLogs,
                                totalCalories: _controller.filteredLogs.fold(
                                  0,
                                  (sum, item) => sum + item.calories,
                                ),
                                selectedDate: _controller.selectedDate,
                                recentCatalog: _controller.recentCatalog,
                                recentlyAddedFoodNames: _recentlyAddedFoodNames,
                                onAddFood: _openAddFoodModal,
                                onOpenDetail: _openDetailModal,
                                onOpenAllCatalog: () => _openAllCatalogModal(
                                  _tabs[_selectedTabIndex],
                                ),
                                onQuickAdd: _quickAddFood,
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
