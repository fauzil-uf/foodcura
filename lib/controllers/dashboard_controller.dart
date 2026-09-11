import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_log_model.dart';
import '../models/pantry_item_model.dart';
import '../models/user_model.dart';
import '../services/app_notifiers.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';
import '../services/streak_service.dart';
import '../services/sync_service.dart';

//// Controller dashboard / home (ringkasan kalori, nutrisi, radar pantry, & saran AI).
class DashboardController extends ChangeNotifier {
  final DBHelper _db;
  final GeminiService _gemini;
  final StreakService _streakService;
  final ReminderService _reminderService;

  DashboardController({
    DBHelper? db,
    GeminiService? gemini,
    StreakService? streakService,
    ReminderService? reminderService,
  }) : _db = db ?? DBHelper(),
       _gemini = gemini ?? GeminiService.instance,
       _streakService = streakService ?? StreakService(db: db ?? DBHelper()),
       _reminderService =
           reminderService ?? ReminderService(db: db ?? DBHelper());

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

  StreamSubscription<User?>? _authSubscription;
  final List<StreamSubscription> _cloudSubscriptions = [];
  String? _subscribedUid;
  Timer? _debounceTimer;

  UserModelSQL? get user => _user;
  int get streak => _streak;
  int get totalCalories => _totalCalories;
  int get targetCalories => defaultTargetCalories;
  double get caloriesRatio =>
      (_totalCalories / defaultTargetCalories).clamp(0.0, 1.0);

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
    await _db.deleteNotificationsByPantryId(id);
    await NotificationService.instance.cancelPantryNotifications(id);
    await _reminderService.syncPantryExpiryAlarms();
    await NotificationNotifier.instance.refresh();
    await loadDashboardData();
  }

  bool _isDataLoading = false;

  /// Memuat semua data metrik dashboard secara paralel
  Future<void> loadDashboardData() async {
    if (_isDataLoading) return;
    _isDataLoading = true;
    _isLoading = true;
    notifyListeners();

    try {
      final todayStr = AppDateFormatter.formatToday();

      // Jalankan pengecekan pengingat notifikasi (membuat notifikasi jika ada yang jatuh tempo)
      await _reminderService.checkExpiryAndCreateNotifications();
      await _reminderService.checkMealRemindersAndCreateNotifications();

      // Eksekusi query data dashboard beserta jumlah notifikasi yang sudah mutakhir
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
          .where(
            (item) =>
                item.expiryStatus == 'expired' || item.expiryStatus == 'urgent',
          )
          .toList();
      _segeraPantryItems = allPantry
          .where((item) => item.expiryStatus == 'segera')
          .toList();

      // Hitung total akumulasi makronutrisi harian secara in-memory untuk efisiensi render UI tinggi.
      _totalCalories = _todayLogs.fold(0, (sum, log) => sum + log.calories);
      _proteinGrams = _todayLogs.fold(0.0, (s, l) => s + l.protein);
      _carbsGrams = _todayLogs.fold(0.0, (s, l) => s + l.carbs);
      _lemakGrams = _todayLogs.fold(0.0, (s, l) => s + l.fat);
      _kolesterolMg = _todayLogs.fold(0.0, (s, l) => s + l.cholesterol);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      _isDataLoading = false;
      notifyListeners();
    }
  }

  /// Meminta izin notifikasi sistem jika pengguna belum mengaktifkannya
  Future<void> requestNotificationPermissionsIfFirstTime() async {
    try {
      final allowed = await NotificationService.instance
          .areNotificationsEnabled();
      if (!allowed) {
        await NotificationService.instance.requestPermissions();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission on dashboard: $e');
    }
  }

  /// Memperbarui badge hitungan notifikasi belum terbaca secara efisien.
  Future<void> refreshUnreadCount() async {
    _unreadNotifications = await _db.getUnreadNotificationCount();
    notifyListeners();
  }

  void _debouncedLoadDashboardData() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadDashboardData();
    });
  }

  /// Memulai sinkronisasi otomatis stream Cloud Firestore ke SQLite lokal untuk Dashboard.
  void startCloudSync() {
    try {
      _authSubscription?.cancel();
      _authSubscription = AuthService.instance.authStateChanges.listen((user) {
        final uid = user?.uid;
        if (uid != null) {
          _subscribeToCloud(uid);
        } else {
          _cancelCloudSubscriptions();
        }
      });

      final currentUid = AuthService.instance.currentUser?.uid;
      if (currentUid != null) {
        _subscribeToCloud(currentUid);
      }
    } catch (e) {
      debugPrint('[DashboardController] Gagal setup cloud sync: $e');
    }
  }

  void _subscribeToCloud(String uid) {
    if (_subscribedUid == uid) return;
    _subscribedUid = uid;
    _cancelCloudSubscriptions();

    _cloudSubscriptions.add(
      FirestoreService.instance.streamPantryItems(uid).listen((_) {
        _debouncedLoadDashboardData();
      }),
    );
    _cloudSubscriptions.add(
      FirestoreService.instance.streamFoodLogs(uid).listen((_) {
        _debouncedLoadDashboardData();
      }),
    );
    _cloudSubscriptions.add(
      FirestoreService.instance.streamUserProfile(uid).listen((_) {
        _debouncedLoadDashboardData();
      }),
    );
    _cloudSubscriptions.add(
      FirestoreService.instance.streamNotifications(uid).listen((_) async {
        await SyncService.instance.syncNotificationsFromCloud();
        refreshUnreadCount();
      }),
    );
  }

  void _cancelCloudSubscriptions() {
    for (final sub in _cloudSubscriptions) {
      sub.cancel();
    }
    _cloudSubscriptions.clear();
    _subscribedUid = null;
  }

  /// Sinkronisasi menyeluruh dari Cloud Firestore ke database lokal untuk Dashboard.
  Future<void> syncCloudDashboard() async {
    try {
      await Future.wait([
        SyncService.instance.syncUserProfileFromCloud(),
        SyncService.instance.syncPantryFromCloud(),
        SyncService.instance.syncFoodLogsFromCloud(),
        SyncService.instance.syncNotificationsFromCloud(),
      ]);
    } catch (e) {
      debugPrint('[DashboardController] Gagal sync dashboard dari cloud: $e');
    }
    await loadDashboardData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSubscription?.cancel();
    _cancelCloudSubscriptions();
    super.dispose();
  }
}
