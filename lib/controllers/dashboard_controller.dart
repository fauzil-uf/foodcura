import 'package:flutter/foundation.dart';

import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_log_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';
import '../services/gemini_service.dart';
import '../services/streak_service.dart';

/// Controller untuk mengelola data dan kalkulasi ringkasan harian pada layar Dashboard/Home.
class DashboardController extends ChangeNotifier {
  final DBHelper _db;
  final GeminiService _gemini;
  final StreakService _streakService;

  DashboardController({
    DBHelper? db,
    GeminiService? gemini,
    StreakService? streakService,
  })  : _db = db ?? DBHelper(),
        _gemini = gemini ?? GeminiService.instance,
        _streakService = streakService ?? StreakService(db: db ?? DBHelper());

  static const int defaultTargetCalories = 2000;
  static const double defaultProteinMax = 65.0;
  static const double defaultCarbsMax = 300.0;
  static const double defaultLemakMax = 67.0;
  static const double defaultKolesterolMax = 300.0;

  UserModelSQL? _user;
  int _streak = 0;
  int _totalCalories = 0;
  double _proteinGrams = 0;
  double _carbsGrams = 0;
  double _lemakGrams = 0;
  double _kolesterolMg = 0;
  List<PantryItemModel> _urgentPantryItems = [];
  List<PantryItemModel> _segeraPantryItems = [];
  List<FoodLogModel> _todayLogs = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;

  String? _aiNutritionAdvice;
  bool _isAiAdviceLoading = false;

  // Getters
  UserModelSQL? get user => _user;
  int get streak => _streak;
  int get totalCalories => _totalCalories;
  int get targetCalories => defaultTargetCalories;
  double get caloriesRatio => (_totalCalories / defaultTargetCalories).clamp(0.0, 1.0);

  double get proteinGrams => _proteinGrams;
  double get proteinMax => defaultProteinMax;
  double get carbsGrams => _carbsGrams;
  double get carbsMax => defaultCarbsMax;
  double get lemakGrams => _lemakGrams;
  double get lemakMax => defaultLemakMax;
  double get kolesterolMg => _kolesterolMg;
  double get kolesterolMax => defaultKolesterolMax;

  List<PantryItemModel> get urgentPantryItems => _urgentPantryItems;
  List<PantryItemModel> get segeraPantryItems => _segeraPantryItems;
  List<FoodLogModel> get todayLogs => _todayLogs;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;

  String? get aiNutritionAdvice => _aiNutritionAdvice;
  bool get isAiAdviceLoading => _isAiAdviceLoading;

  /// Meminta analisis dan saran personal dari AI Nutrition Coach
  Future<void> fetchAiNutritionAdvice() async {
    _isAiAdviceLoading = true;
    notifyListeners();

    try {
      _aiNutritionAdvice = await _gemini.evaluateDailyNutrition(
        calories: _totalCalories,
        protein: _proteinGrams,
        carbs: _carbsGrams,
        fat: _lemakGrams,
        cholesterol: _kolesterolMg,
      );
    } catch (e) {
      debugPrint('Error fetching AI advice: $e');
    } finally {
      _isAiAdviceLoading = false;
      notifyListeners();
    }
  }

  /// Menandai bahan makanan di pantry sudah digunakan langsung dari Dashboard
  Future<void> markPantryItemUsed(int id) async {
    await _db.markPantryItemUsed(id);
    await loadDashboardData();
  }

  /// Memuat semua data metrik dashboard secara paralel
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final todayStr = AppDateFormatter.formatToday();

      // Eksekusi seluruh query SQLite metrik dashboard secara paralel untuk memangkas waktu inisialisasi UI.
      final results = await Future.wait([
        _db.getLoggedInUser(),
        _streakService.computeAndSaveStreak(),
        _db.getFoodLogs(date: todayStr),
        _db.getPantryItems(),
        _db.getUnreadNotificationCount(),
      ]);

      _user = results[0] as UserModelSQL?;
      _streak = results[1] as int;
      _todayLogs = results[2] as List<FoodLogModel>;
      final allPantry = results[3] as List<PantryItemModel>;
      _unreadNotifications = results[4] as int;

      _urgentPantryItems = allPantry
          .where((item) => item.expiryStatus == 'expired' || item.expiryStatus == 'urgent')
          .toList();
      _segeraPantryItems = allPantry
          .where((item) => item.expiryStatus == 'segera')
          .toList();

      // Hitung total akumulasi makronutrisi harian secara in-memory untuk efisiensi render UI tinggi.
      _totalCalories = _todayLogs.fold(0, (s, l) => s + l.calories);
      _proteinGrams = _todayLogs.fold(0.0, (s, l) => s + l.protein);
      _carbsGrams = _todayLogs.fold(0.0, (s, l) => s + l.carbs);
      _lemakGrams = _todayLogs.fold(0.0, (s, l) => s + l.fat);
      _kolesterolMg = _todayLogs.fold(0.0, (s, l) => s + l.cholesterol);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
