import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';

/// Controller untuk mengelola pencatatan makanan, filter waktu makan,
/// kalkulasi nutrisi harian, dan peringatan batas nutrisi.
class FoodTrackerController extends ChangeNotifier {
  final DBHelper _db;

  FoodTrackerController({DBHelper? db}) : _db = db ?? DBHelper();

  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();

  List<FoodLogModel> _allLogs = [];
  List<FoodItemModel> _recentCatalog = [];
  List<FoodItemModel> _searchResults = [];
  List<Map<String, dynamic>> _warnings = [];

  bool _isLoading = true;
  bool _isSearching = false;

  static const List<String> _tabs = [
    'Semua',
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  DateTime get selectedDate => _selectedDate;
  List<String> get tabs => _tabs;
  String get currentTabName => _tabs[_selectedTabIndex];

  List<FoodLogModel> get allLogs => _allLogs;
  List<FoodItemModel> get recentCatalog => _recentCatalog;
  List<FoodItemModel> get searchResults => _searchResults;
  List<Map<String, dynamic>> get warnings => _warnings;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  List<FoodLogModel> get filteredLogs => _selectedTabIndex == 0
      ? _allLogs
      : _allLogs.where((l) => l.mealType == _tabs[_selectedTabIndex]).toList();

  List<FoodLogModel> get sarapanLogs => _allLogs.where((l) => l.mealType == 'Sarapan').toList();
  List<FoodLogModel> get makanSiangLogs => _allLogs.where((l) => l.mealType == 'Makan Siang').toList();
  List<FoodLogModel> get makanMalamLogs => _allLogs.where((l) => l.mealType == 'Makan Malam').toList();
  List<FoodLogModel> get camilanLogs => _allLogs.where((l) => l.mealType == 'Camilan').toList();

  int get totalCalories => _allLogs.fold(0, (sum, log) => sum + log.calories);
  double get totalProtein => _allLogs.fold(0.0, (sum, log) => sum + log.protein);
  double get totalCarbs => _allLogs.fold(0.0, (sum, log) => sum + log.carbs);
  double get totalFat => _allLogs.fold(0.0, (sum, log) => sum + log.fat);
  double get totalCholesterol => _allLogs.isEmpty ? 0.0 : totalFat * 4.5 + totalProtein * 3.5;

  bool get isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return _selectedDate.year == y.year &&
        _selectedDate.month == y.month &&
        _selectedDate.day == y.day;
  }

  String get dateDisplayLabel {
    if (isToday) return 'Hari Ini, ${_selectedDate.toShortDate()}';
    if (isYesterday) return 'Kemarin, ${_selectedDate.toShortDate()}';
    return _selectedDate.toDayDate();
  }

  /// Memuat data log makanan dan katalog terkini
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = _selectedDate.toFullDate();
      final logs = await _db.getFoodLogs(date: dateStr);
      final catalog = await _db.getRecentAddedFoods();

      _allLogs = logs;
      _recentCatalog = catalog;
      _calculateWarnings();
    } catch (e) {
      debugPrint('Error loading food tracker data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadData();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadData();
  }

  void nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    loadData();
  }

  void setToday() {
    _selectedDate = DateTime.now();
    loadData();
  }

  void setYesterday() {
    _selectedDate = DateTime.now().subtract(const Duration(days: 1));
    loadData();
  }

  /// Menghitung peringatan batas nutrisi secara efisien
  void _calculateWarnings() {
    _warnings = [];

    void addWarn(String title, String msg, Color color, IconData icon) {
      _warnings.add({'title': title, 'message': msg, 'color': color, 'icon': icon});
    }

    if (totalFat >= 67.0) {
      addWarn(
        'Peringatan Lemak Tinggi!',
        'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / 67g) telah melebihi batas anjuran harian Kemenkes (67g). Batasi gorengan & santan.',
        AppColors.urgent,
        Icons.warning_amber_rounded,
      );
    } else if (totalFat >= 55.0) {
      addWarn(
        'Perhatian Lemak',
        'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / 67g) mendekati batas harian disarankan (67g).',
        AppColors.secondaryContainer,
        Icons.info_outline_rounded,
      );
    }

    if (totalCalories > 2000) {
      addWarn(
        'Peringatan Kalori Berlebih!',
        'Total kalori ($totalCalories kcal / 2000 kcal) telah melebihi batas harian rekomendasi.',
        AppColors.urgent,
        Icons.local_fire_department_rounded,
      );
    }

    if (totalCholesterol > 300.0) {
      addWarn(
        'Peringatan Kolesterol Tinggi!',
        'Estimasi kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / 300mg) telah melebihi batas yang disarankan.',
        AppColors.urgent,
        Icons.favorite_border_rounded,
      );
    }

    if (totalCarbs > 300.0) {
      addWarn(
        'Peringatan Karbohidrat Tinggi!',
        'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / 300g) telah melebihi rekomendasi harian.',
        AppColors.secondaryContainer,
        Icons.bakery_dining_rounded,
      );
    }

    if (totalProtein > 65.0) {
      addWarn(
        'Peringatan Protein Tinggi!',
        'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / 65g) telah melebihi rekomendasi harian Anda.',
        AppColors.secondaryContainer,
        Icons.fitness_center_rounded,
      );
    }
  }

  /// Menambahkan log makanan baru ke database
  Future<NotificationModel?> addFoodLog(FoodLogModel log) async {
    final notif = await _db.addFoodLog(log);
    await loadData();
    return notif;
  }

  /// Menghapus log makanan berdasarkan id
  Future<void> deleteFoodLog(int id) async {
    await _db.deleteFoodLog(id);
    await loadData();
  }

  /// Mencari katalog makanan
  Future<void> searchCatalog(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _db.searchFoodCatalog(q);
    } catch (e) {
      debugPrint('Error searching catalog: $e');
    } finally {
      notifyListeners();
    }
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }
}
