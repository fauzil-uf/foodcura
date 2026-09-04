import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

// Service pemantau batas asupan gizi harian (AKG) & pemicu notifikasi peringatan
class NutritionService {
  final DBHelper _db;
  final NotificationService _notificationService;

  NutritionService({DBHelper? db, NotificationService? notificationService})
    : _db = db ?? DBHelper(),
      _notificationService =
          notificationService ?? NotificationService.instance;

  static const double maxDailyFat = 67.0;
  static const int maxDailyCalories = 2000;
  static const double maxDailyCholesterol = 300.0;
  static const double maxDailyCarbs = 300.0;
  static const double maxDailyProtein = 65.0;

  // Cek asupan gizi hari ini, picu notifikasi jika melebihi batas AKG
  Future<NotificationModel?> checkNutritionExcess({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true)) {
      return null;
    }

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) {
      return null;
    }

    final db = await _db.database;
    final todayStr = AppDateFormatter.formatToday();
    final logs = await db.query(
      DBHelper.tableFoodLogs,
      where: 'date = ? AND user_id = ?',
      whereArgs: [todayStr, targetUserId],
    );
    if (logs.isEmpty) {
      for (final kw in ['Lemak', 'Kalori', 'Kolesterol', 'Karbohidrat', 'Protein']) {
        await resetNutrientTracking(targetUserId, kw);
        try {
          await _db.deleteNutritionNotifications(kw, userId: targetUserId);
        } catch (_) {}
      }
      return null;
    }

    int totalCalories = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCholesterol = 0;
    for (var log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
      totalCholesterol += ((log['cholesterol'] as num?) ?? 0.0).toDouble();
    }

    final allNutrients = {
      'Lemak': totalFat >= maxDailyFat,
      'Kalori': totalCalories > maxDailyCalories,
      'Kolesterol': totalCholesterol > maxDailyCholesterol,
      'Karbohidrat': totalCarbs > maxDailyCarbs,
      'Protein': totalProtein > maxDailyProtein,
    };

    // Smart Hysteresis: jika asupan nutrisi kembali ke zona aman (<= batas),
    // bersihkan tracking peringatan agar jika nanti naik lagi bisa diperingatkan kembali.
    for (final entry in allNutrients.entries) {
      if (!entry.value) {
        await resetNutrientTracking(targetUserId, entry.key);
        try {
          await _db.deleteNutritionNotifications(entry.key, userId: targetUserId);
        } catch (_) {}
      }
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    NotificationModel? result;
    void setResult(NotificationModel n) => result ??= n;

    final rules = [
      if (allNutrients['Lemak']!)
        (
          'Lemak',
          'Peringatan Lemak Tinggi!',
          'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / ${maxDailyFat.toStringAsFixed(0)}g) telah melebihi batas anjuran harian Kemenkes (67g). Batasi gorengan & makanan berminyak.',
        ),
      if (allNutrients['Kalori']!)
        (
          'Kalori',
          'Peringatan Kalori Berlebih!',
          'Total asupan kalori ($totalCalories kcal / $maxDailyCalories kcal) telah melebihi target harian Anda.',
        ),
      if (allNutrients['Kolesterol']!)
        (
          'Kolesterol',
          'Peringatan Kolesterol Tinggi!',
          'Asupan kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / ${maxDailyCholesterol.toStringAsFixed(0)}mg) telah melebihi batas anjuran harian Kemenkes (300mg). Batasi makanan hewani tinggi lemak dan jeroan.',
        ),
      if (allNutrients['Karbohidrat']!)
        (
          'Karbohidrat',
          'Peringatan Karbohidrat Tinggi!',
          'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / ${maxDailyCarbs.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        ),
      if (allNutrients['Protein']!)
        (
          'Protein',
          'Peringatan Protein Tinggi!',
          'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / ${maxDailyProtein.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        ),
    ];

    final newlyExceeded = <String>[];
    for (final rule in rules) {
      final wasInserted = await _checkAndRecord(
        keyword: rule.$1,
        startOfDay: startOfDay,
        title: rule.$2,
        message: rule.$3,
        getContainer: () => result,
        setContainer: setResult,
        userId: targetUserId,
      );
      if (wasInserted) {
        newlyExceeded.add(rule.$1);
      }
    }

    // Multi-Nutrient Bundling: Jika 2 atau lebih nutrisi tembus batas bersamaan,
    // satukan notifikasi sistem Android menjadi 1 ringkasan elegan agar tidak spam.
    if (newlyExceeded.length == 1) {
      final kw = newlyExceeded.first;
      final singleRule = rules.firstWhere((r) => r.$1 == kw);
      final systemNotifId = getSystemNotifId(kw);
      try {
        await _notificationService.showSystemNotification(
          id: systemNotifId,
          title: singleRule.$2,
          body: singleRule.$3,
        );
      } catch (_) {}
    } else if (newlyExceeded.length > 1) {
      final joinedNutrients = newlyExceeded.join(', ');
      try {
        await _notificationService.showSystemNotification(
          id: 40000,
          title: 'Peringatan Asupan Harian: $joinedNutrients Berlebih!',
          body:
              'Asupan $joinedNutrients Anda hari ini telah melebihi batas anjuran harian. Periksa rincian menu Anda di Food Tracker.',
        );
      } catch (_) {}
    }

    return result;
  }

  static int getSystemNotifId(String keyword) {
    if (keyword.contains('Lemak')) return 40001;
    if (keyword.contains('Kalori')) return 40002;
    if (keyword.contains('Kolesterol')) return 40003;
    if (keyword.contains('Karbohidrat')) return 40004;
    if (keyword.contains('Protein')) return 40005;
    return 40000;
  }

  Future<bool> _checkAndRecord({
    required String keyword,
    required String startOfDay,
    required String title,
    required String message,
    required NotificationModel? Function() getContainer,
    required void Function(NotificationModel) setContainer,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 0. Cek jika pengguna sudah menghapus notifikasi peringatan nutrisi ini hari ini
    final dismissedKey = 'dismissed_nutrition_${userId}_$keyword';
    if (prefs.getString(dismissedKey) == todayDateStr) {
      return false;
    }

    // 1. Hanya kirim 1x per siklus kenaikan; jangan duplikasi jika sudah dikirim hari ini
    final dailyNotifKey = 'last_notif_nutrition_${userId}_$keyword';
    if (prefs.getString(dailyNotifKey) == todayDateStr) {
      return false;
    }

    final db = await _db.database;
    final existing = await db.query(
      DBHelper.tableNotifications,
      where: 'title LIKE ? AND created_at >= ? AND user_id = ?',
      whereArgs: ['%$keyword%', startOfDay, userId],
    );

    if (existing.isEmpty) {
      final notif = NotificationModel(
        userId: userId,
        title: title,
        message: message,
        type: 'nutrition_excess',
        iconType: 'warning',
        createdAt: DateTime.now(),
      );
      final id = await _db.addNotification(notif);
      await prefs.setString(dailyNotifKey, todayDateStr);

      if (getContainer() == null) {
        setContainer(notif.copyWith(id: id));
      }
      return true;
    } else {
      await prefs.setString(dailyNotifKey, todayDateStr);
      return false;
    }
  }


  /// Mencatat bahwa notifikasi peringatan nutrisi telah dihapus oleh pengguna hari ini
  static Future<void> recordDismissedNutritionNotification(
    int userId,
    String keyword,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setString('dismissed_nutrition_${userId}_$keyword', todayDateStr);
  }

  /// Mereset tracking peringatan nutrisi ke zona aman saat asupan kembali normal
  static Future<void> resetNutrientTracking(int userId, String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notif_nutrition_${userId}_$keyword');
    await prefs.remove('dismissed_nutrition_${userId}_$keyword');
  }
}


