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

  UserModelSQL? _user;
  int _ecoPoints = 0;
  int _streak = 0;
  int _totalCalories = 0;
  final int _targetCalories = 2000;

  double _proteinGrams = 0;
  final double _proteinMax = 65.0;

  double _carbsGrams = 0;
  final double _carbsMax = 300.0;

  double _lemakGrams = 0;
  final double _lemakMax = 67.0;

  double _kolesterolMg = 0;
  final double _kolesterolMax = 300.0;

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
  int get targetCalories => _targetCalories;
  double get caloriesRatio =>
      (_totalCalories / _targetCalories).clamp(0.0, 1.0);

  double get proteinGrams => _proteinGrams;
  double get proteinMax => _proteinMax;
  double get carbsGrams => _carbsGrams;
  double get carbsMax => _carbsMax;
  double get lemakGrams => _lemakGrams;
  double get lemakMax => _lemakMax;
  double get kolesterolMg => _kolesterolMg;
  double get kolesterolMax => _kolesterolMax;

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
      final advice = await _gemini.evaluateDailyNutrition(
        calories: _totalCalories,
        protein: _proteinGrams,
        carbs: _carbsGrams,
        fat: _lemakGrams,
        cholesterol: _kolesterolMg,
      );
      _aiNutritionAdvice = advice;
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

      // Kalkulasi total nutrisi
      int cals = 0;
      double prot = 0;
      double carbs = 0;
      double fat = 0;

      for (final log in _todayLogs) {
        cals += log.calories;
        prot += log.protein;
        carbs += log.carbs;
        fat += log.fat;
      }

      _totalCalories = cals;
      _proteinGrams = prot;
      _carbsGrams = carbs;
      _lemakGrams = fat;
      _kolesterolMg = (fat * 4.5 + prot * 3.5).clamp(0.0, 500.0);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
