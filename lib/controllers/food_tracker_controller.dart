import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_item_model.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import '../models/nutrient_warning_model.dart';
import '../services/app_notifiers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/nutrition_service.dart';
import '../services/reminder_service.dart';
import '../services/streak_service.dart';
import '../services/sync_service.dart';
import 'mixins/cloud_sync_controller_mixin.dart';

//// Controller pencatatan makanan, tracking nutrisi, & batas AKG
class FoodTrackerController extends ChangeNotifier
    with CloudSyncControllerMixin {
  final DBHelper _db;
  final NutritionService _nutritionService;
  final StreakService _streakService;
  final ReminderService _reminderService;
  Timer? _searchDebounce;

  FoodTrackerController({
    DBHelper? db,
    NutritionService? nutritionService,
    StreakService? streakService,
    ReminderService? reminderService,
  }) : _db = db ?? DBHelper(),
       _nutritionService =
           nutritionService ?? NutritionService(db: db ?? DBHelper()),
       _streakService = streakService ?? StreakService(db: db ?? DBHelper()),
       _reminderService =
           reminderService ?? ReminderService(db: db ?? DBHelper());

  int _selectedTabIndex = 0;
  DateTime _selectedDate = DateTime.now();

  List<FoodLogModel> _allLogs = [];
  List<FoodItemModel> _recentCatalog = [];
  List<FoodItemModel> _searchResults = [];
  List<NutrientWarningModel> _warnings = [];
  int _unreadNotifications = 0;

  bool _isLoading = true;
  bool _isSearching = false;

  static const List<String> _tabs = [
    'Semua',
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  int get selectedTabIndex => _selectedTabIndex;
  DateTime get selectedDate => _selectedDate;
  List<String> get tabs => _tabs;
  String get currentTabName => _tabs[_selectedTabIndex];

  List<FoodLogModel> get allLogs => _allLogs;
  List<FoodItemModel> get recentCatalog => _recentCatalog;
  List<FoodItemModel> get searchResults => _searchResults;
  List<NutrientWarningModel> get warnings => _warnings;
  int get unreadNotifications => _unreadNotifications;

  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  List<FoodLogModel> get filteredLogs => _selectedTabIndex == 0
      ? _allLogs
      : _allLogs
            .where(
              (l) =>
                  l.mealType.trim().toLowerCase() ==
                  _tabs[_selectedTabIndex].trim().toLowerCase(),
            )
            .toList();

  /// Helper: mendapatkan log berdasarkan nama meal type secara generik.
  List<FoodLogModel> logsForMeal(String mealType) => _allLogs
      .where(
        (l) => l.mealType.trim().toLowerCase() == mealType.trim().toLowerCase(),
      )
      .toList();

  int get totalCalories => _allLogs.fold(0, (sum, log) => sum + log.calories);
  double get totalProtein =>
      _allLogs.fold(0.0, (sum, log) => sum + log.protein);
  double get totalCarbs => _allLogs.fold(0.0, (sum, log) => sum + log.carbs);
  double get totalFat => _allLogs.fold(0.0, (sum, log) => sum + log.fat);
  double get totalCholesterol =>
      _allLogs.fold(0.0, (sum, log) => sum + log.cholesterol);

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

  /// Memuat data log makanan, katalog terkini, dan unread notifikasi
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = _selectedDate.toFullDate();
      final logs = await _db.getFoodLogs(date: dateStr);
      final catalog = await _db.getRecentAddedFoods();
      final unread = await _db.getUnreadNotificationCount();

      _allLogs = logs;
      _recentCatalog = catalog;
      _unreadNotifications = unread;
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

  bool get canGoNextDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return current.isBefore(today);
  }

  void setSelectedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    _selectedDate = target.isAfter(today) ? today : date;
    loadData();
  }

  void previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    loadData();
  }

  void nextDay() {
    if (!canGoNextDay) return;
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

  void _calculateWarnings() {
    _warnings = [];

    void addWarn(
      String title,
      String msg,
      String nutrient,
      NutrientWarningSeverity severity,
    ) {
      _warnings.add(
        NutrientWarningModel(
          title: title,
          message: msg,
          nutrient: nutrient,
          severity: severity,
        ),
      );
    }

    if (totalFat >= NutritionService.maxDailyFat) {
      addWarn(
        'Peringatan Lemak Tinggi!',
        'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / ${NutritionService.maxDailyFat.toStringAsFixed(0)}g) telah melebihi batas anjuran harian Kemenkes (${NutritionService.maxDailyFat.toStringAsFixed(0)}g). Batasi gorengan & santan.',
        NutritionService.nutrientFat,
        NutrientWarningSeverity.alert,
      );
    } else if (totalFat >= 55.0) {
      addWarn(
        'Perhatian Lemak',
        'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / ${NutritionService.maxDailyFat.toStringAsFixed(0)}g) mendekati batas harian disarankan (${NutritionService.maxDailyFat.toStringAsFixed(0)}g).',
        NutritionService.nutrientFat,
        NutrientWarningSeverity.caution,
      );
    }

    if (totalCalories > NutritionService.maxDailyCalories) {
      addWarn(
        'Peringatan Kalori Berlebih!',
        'Total kalori ($totalCalories kcal / ${NutritionService.maxDailyCalories} kcal) telah melebihi batas harian rekomendasi.',
        NutritionService.nutrientCalories,
        NutrientWarningSeverity.alert,
      );
    }

    if (totalCholesterol > NutritionService.maxDailyCholesterol) {
      addWarn(
        'Peringatan Kolesterol Tinggi!',
        'Estimasi kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / ${NutritionService.maxDailyCholesterol.toStringAsFixed(0)}mg) telah melebihi batas yang disarankan.',
        NutritionService.nutrientCholesterol,
        NutrientWarningSeverity.alert,
      );
    }

    if (totalCarbs > NutritionService.maxDailyCarbs) {
      addWarn(
        'Peringatan Karbohidrat Tinggi!',
        'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / ${NutritionService.maxDailyCarbs.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        NutritionService.nutrientCarbs,
        NutrientWarningSeverity.caution,
      );
    }

    if (totalProtein > NutritionService.maxDailyProtein) {
      addWarn(
        'Peringatan Protein Tinggi!',
        'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / ${NutritionService.maxDailyProtein.toStringAsFixed(0)}g) telah melebihi rekomendasi harian Anda.',
        NutritionService.nutrientProtein,
        NutrientWarningSeverity.caution,
      );
    }
  }

  /// Menambahkan log makanan baru ke database dan memicu evaluasi AKG
  Future<NotificationModel?> addFoodLog(FoodLogModel log) async {
    final activeUserId = log.userId ?? await _db.getActiveUserId();
    final logWithUser = activeUserId != null
        ? log.copyWith(userId: activeUserId)
        : log;
    final id = await _db.insertFoodLog(logWithUser);
    final logWithId = logWithUser.copyWith(id: id);

    // Sinkronisasi catatan makan ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      await FirestoreService.instance.addFoodLog(uid, logWithId);
    } catch (e) {
      debugPrint(
        '[FoodTrackerController] Gagal sync addFoodLog ke Firestore: $e',
      );
    }

    final todayStr = AppDateFormatter.formatToday();
    if (logWithUser.date == todayStr && activeUserId != null) {
      await _reminderService.cancelAndDismissMealReminder(
        activeUserId,
        logWithUser.mealType,
      );
    }
    final notif = await _nutritionService.checkNutritionExcess(
      userId: activeUserId,
    );
    await _streakService.computeAndSaveStreak(userId: activeUserId);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    FoodLogUpdateNotifier.instance.notifyFoodLogsChanged();
    await NotificationNotifier.instance.refresh();

    // Sinkronkan tab aktif agar beralih ke jenis makan yang baru ditambahkan
    final mealIndex = _tabs.indexWhere(
      (t) =>
          t.trim().toLowerCase() == logWithUser.mealType.trim().toLowerCase(),
    );
    if (mealIndex != -1 && _selectedTabIndex != 0) {
      _selectedTabIndex = mealIndex;
    }

    await loadData();
    return notif;
  }

  /// Memperbarui log makanan yang sudah ada
  Future<NotificationModel?> updateFoodLog(FoodLogModel log) async {
    final activeUserId = log.userId ?? await _db.getActiveUserId();
    final logWithUser = activeUserId != null
        ? log.copyWith(userId: activeUserId)
        : log;
    await _db.updateFoodLog(logWithUser);

    // Sinkronisasi update ke Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      await FirestoreService.instance.addFoodLog(uid, logWithUser);
    } catch (e) {
      debugPrint(
        '[FoodTrackerController] Gagal sync updateFoodLog ke Firestore: $e',
      );
    }

    final todayStr = AppDateFormatter.formatToday();
    if (logWithUser.date == todayStr && activeUserId != null) {
      await _reminderService.cancelAndDismissMealReminder(
        activeUserId,
        logWithUser.mealType,
      );
    }
    final notif = await _nutritionService.checkNutritionExcess(
      userId: activeUserId,
    );
    await _streakService.computeAndSaveStreak(userId: activeUserId);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    FoodLogUpdateNotifier.instance.notifyFoodLogsChanged();
    await NotificationNotifier.instance.refresh();
    await loadData();
    return notif;
  }

  /// Menghapus log makanan berdasarkan id
  Future<void> deleteFoodLog(int id) async {
    // Optimistic UI update: hapus seketika dari RAM agar UI instan merespons
    _allLogs.removeWhere((l) => l.id == id);
    _calculateWarnings();
    notifyListeners();

    final activeUserId = await _db.getActiveUserId();
    final logs = await _db.getFoodLogs(userId: activeUserId);
    final targetLog = logs.where((l) => l.id == id).firstOrNull;

    await _db.deleteFoodLog(id, userId: activeUserId);

    // Hapus dari Firestore
    try {
      final uid = AuthService.instance.currentUser?.uid ?? 'user_$activeUserId';
      await FirestoreService.instance.deleteFoodLog(uid, 'foodlog_$id');
    } catch (e) {
      debugPrint(
        '[FoodTrackerController] Gagal sync deleteFoodLog ke Firestore: $e',
      );
    }

    if (targetLog != null && activeUserId != null) {
      final todayStr = AppDateFormatter.formatToday();
      if (targetLog.date == todayStr) {
        final remainingLogs = await _db.getFoodLogs(
          date: todayStr,
          userId: activeUserId,
        );
        final hasRemainingForMeal = remainingLogs.any(
          (l) => l.mealType.toLowerCase() == targetLog.mealType.toLowerCase(),
        );

        if (!hasRemainingForMeal) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(
            'dismissed_meal_${activeUserId}_${targetLog.mealType}',
          );
          await prefs.remove(
            'last_notif_meal_${activeUserId}_${targetLog.mealType}',
          );
          await _reminderService.syncMealAlarms();
        }
      }
    }

    await _nutritionService.checkNutritionExcess(userId: activeUserId);
    await _streakService.computeAndSaveStreak(userId: activeUserId);
    PantryUpdateNotifier.instance.notifyPantryChanged();
    FoodLogUpdateNotifier.instance.notifyFoodLogsChanged();
    await NotificationNotifier.instance.refresh();
    await loadData();
  }

  /// Mengambil katalog seluruh makanan yang tersedia
  Future<List<FoodItemModel>> getFoodCatalog() async {
    return await _db.getFoodCatalog();
  }

  /// Mengambil riwayat makanan yang baru ditambahkan
  Future<List<FoodItemModel>> getRecentAddedFoods({int limit = 6}) async {
    return await _db.getRecentAddedFoods(limit: limit);
  }

  /// Menyegarkan hitungan notifikasi belum dibaca
  Future<void> refreshUnreadCount() async {
    _unreadNotifications = await _db.getUnreadNotificationCount();
    notifyListeners();
  }

  /// Mencari katalog makanan dengan debouncing untuk efisiensi CPU & responsivitas.
  void searchCatalog(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    // Debounce 250ms: Menahan query SQLite selama pengguna masih aktif mengetik.
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        _searchResults = await _db.searchFoodCatalog(q, limit: 30);
      } catch (e) {
        debugPrint('Error searching catalog: $e');
      } finally {
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  /// Sinkronisasi catatan makan dari Cloud Firestore ke database lokal
  Future<int> syncCloudFoodLogs() async {
    final count = await SyncService.instance.syncFoodLogsFromCloud();
    await loadData();
    return count;
  }

  /// Mengaktifkan sinkronisasi realtime dari Cloud Firestore
  void startCloudSync() {
    initCloudSyncSubscription(
      streamFactory: (uid) => FirestoreService.instance.streamFoodLogs(uid),
      onDataTriggered: () => syncCloudFoodLogs(),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    cancelCloudSyncSubscription();
    super.dispose();
  }
}
