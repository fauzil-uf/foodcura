import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_log_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';
import '../services/gemini_service.dart';

/// Controller untuk mengelola data dan kalkulasi ringkasan harian pada layar Dashboard/Home.
class DashboardController extends ChangeNotifier {
  final DBHelper _db;
  final GeminiService _gemini;

  DashboardController({DBHelper? db, GeminiService? gemini})
    : _db = db ?? DBHelper(),
      _gemini = gemini ?? GeminiService.instance;

  static const int defaultTargetCalories = 2000;
  static const double defaultProteinMax = 65.0;
  static const double defaultCarbsMax = 300.0;
  static const double defaultLemakMax = 67.0;
  static const double defaultKolesterolMax = 300.0;

  UserModelSQL? _user;
  int _ecoPoints = 0;
  int _streak = 0;
  int _totalCalories = 0;
  double _proteinGrams = 0;
  double _carbsGrams = 0;
  double _lemakGrams = 0;
  double _kolesterolMg = 0;
  int _rescuedCount = 0;
  List<PantryItemModel> _urgentPantryItems = [];
  List<FoodLogModel> _todayLogs = [];
  int _unreadNotifications = 0;
  bool _isLoading = true;

  String? _aiNutritionAdvice;
  bool _isAiAdviceLoading = false;

  // Getters
  UserModelSQL? get user => _user;
  int get ecoPoints => _ecoPoints;
  int get streak => _streak;
  int get rescuedCount => _rescuedCount;
  double get rescuedKg => _rescuedCount * 0.35;
  int get savedMoney => _rescuedCount * 15000;
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

  /// Memuat semua data metrik dashboard secara paralel
  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final todayStr = AppDateFormatter.formatToday();

      final results = await Future.wait([
        _db.getLoggedInUser(),
        _db.computeAndSaveStreak(),
        _db.getFoodLogs(date: todayStr),
        _db.getPantryItems(filter: 'urgent'),
        _db.getUnreadNotificationCount(),
        _db.getUsedPantryItemsCount(),
        SharedPreferences.getInstance(),
      ]);

      _user = results[0] as UserModelSQL?;
      _streak = results[1] as int;
      _todayLogs = results[2] as List<FoodLogModel>;
      _urgentPantryItems = results[3] as List<PantryItemModel>;
      _unreadNotifications = results[4] as int;
      _rescuedCount = results[5] as int;

      final prefs = results[6] as SharedPreferences;
      _ecoPoints = prefs.getInt(EcoPointsNotifier.keyEcoPoints) ?? 0;

      // Akumulasi nutrisi ringkas
      _totalCalories = _todayLogs.fold(0, (s, l) => s + l.calories);
      _proteinGrams = _todayLogs.fold(0.0, (s, l) => s + l.protein);
      _carbsGrams = _todayLogs.fold(0.0, (s, l) => s + l.carbs);
      _lemakGrams = _todayLogs.fold(0.0, (s, l) => s + l.fat);
      _kolesterolMg = (_lemakGrams * 4.5 + _proteinGrams * 3.5).clamp(0.0, 500.0);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
