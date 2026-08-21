import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_date_formatter.dart';
import '../../constants/app_typography.dart';
import '../../controllers/food_tracker_controller.dart';
import '../../models/food_item_model.dart';
import '../../models/food_log_model.dart';
import '../notification/notification_screen.dart';
import '../widgets/app_top_bar.dart';
import 'widgets/add_food_modal.dart';
import 'widgets/all_catalog_modal.dart';
import 'widgets/food_detail_modal.dart';
import 'widgets/food_meal_tab.dart';
import 'widgets/food_search_results.dart';
import 'widgets/food_summary_card.dart';
import 'widgets/food_tracker_header.dart';

class FoodTrackerScreen extends StatefulWidget {
  final int initialTabIndex;

  const FoodTrackerScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FoodTrackerScreen> createState() => _FoodTrackerScreenState();
}

class _FoodTrackerScreenState extends State<FoodTrackerScreen> {
  final _controller = FoodTrackerController();
  final TextEditingController _searchController = TextEditingController();
  // Set penahan untuk mencegah input ganda akibat ketukan cepat (anti-spam).
  final Set<String> _recentlyAddedFoodNames = {};

  List<String> get _tabs => _controller.tabs;
  int get _selectedTabIndex => _controller.selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _controller.setSelectedTab(widget.initialTabIndex);
    // Pasang listener reaktif agar UI otomatis render ulang saat state controller berubah.
    _controller.addListener(_onControllerChanged);
    _refreshData();
  }

  @override
  void dispose() {
    // Lepas listener dan matikan controller saat keluar layar guna mencegah kebocoran memori.
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshData() async {
    // Muat ulang data log harian dan perbarui counter notifikasi belum terbaca.
    await _controller.loadData();
  }

  void _openNotifications() {
    // Buka layar notifikasi dan refresh data setelah kembali.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    ).then((_) => _refreshData());
  }

  void _onSearchChanged(String query) {
    // Teruskan kata kunci pencarian ke controller dengan debouncing.
    _controller.searchCatalog(query);
  }

  void _openAddFoodModal(String mealType) {
    // Tampilkan modal pencatatan makanan untuk jenis waktu makan tertentu.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        initialMealType: mealType,
        targetDate: _controller.selectedDate,
        controller: _controller,
        onFoodAdded: _refreshData,
      ),
    );
  }

  void _openAllCatalogModal(String mealType) {
    // Tampilkan modal katalog lengkap seluruh makanan TKPI.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllCatalogModal(
        currentMealType: mealType,
        targetDate: _controller.selectedDate,
        controller: _controller,
        onFoodAdded: _refreshData,
      ),
    );
  }

  void _openDetailModal(FoodLogModel log) {
    // Tampilkan modal rincian nutrisi dan opsi hapus log makanan.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodDetailModal(
        log: log,
        controller: _controller,
        onLogDeleted: _refreshData,
      ),
    );
  }

  void _openFoodScanner() {
    // Handler sementara untuk fitur pemindai barcode & foto makanan.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Scan Barcode & Foto Makanan belum tersedia'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _quickAddFood(FoodItemModel food, String mealType) async {
    // Abaikan jika item ini sedang dalam proses penyimpanan.
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
      cholesterol: food.cholesterol,
      imagePath: food.imagePath,
      time: timeStr,
      date: AppDateFormatter.formatToday(targetDate),
    );

    final notif = await _controller.addFoodLog(newLog);
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

    // Buka kembali kunci tombol setelah 1,6 detik untuk input berikutnya.
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      setState(() {
        _recentlyAddedFoodNames.remove(food.name);
      });
    }
  }

  /// Membangun antarmuka pelacak makanan dengan navigator tanggal, pencarian instan, ringkasan makronutrisi, dan tab waktu makan.
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
                          FoodTrackerHeader(
                            tabs: _tabs,
                            selectedTabIndex: _selectedTabIndex,
                            selectedDate: _controller.selectedDate,
                            dateDisplayLabel: _controller.dateDisplayLabel,
                            searchController: _searchController,
                            isSearching: _controller.isSearching,
                            onBack: () => _controller.setSelectedTab(0),
                            onDateTap: () async {
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
                            onPreviousDay: () => _controller.previousDay(),
                            onNextDay: () => _controller.nextDay(),
                            onSearchChanged: _onSearchChanged,
                            onFoodScannerTap: _openFoodScanner,
                            onTabChanged: (index) => _controller.setSelectedTab(index),
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
                              onOpenMealTab: (index) => _controller.setSelectedTab(index),
                            )
                          else
                            FoodMealTab(
                              mealType: _tabs[_selectedTabIndex],
                              logs: _controller.allLogs
                                  .where((log) => log.mealType == _tabs[_selectedTabIndex])
                                  .toList(),
                              totalCalories: _controller.allLogs
                                  .where((log) => log.mealType == _tabs[_selectedTabIndex])
                                  .fold(0, (sum, item) => sum + item.calories),
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
          ],
        ),
      ),
    );
  }
}
