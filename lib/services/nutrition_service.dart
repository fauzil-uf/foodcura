import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service pemantau batas asupan gizi harian (AKG) & pemicu notifikasi peringatan nutrisi.
class NutritionService {
  final DBHelper _db;
  final NotificationService _notificationService;

  NutritionService({DBHelper? db, NotificationService? notificationService})
    : _db = db ?? DBHelper(),
      _notificationService =
          notificationService ?? NotificationService.instance;

  // Batas Angka Kecukupan Gizi (AKG) Harian Kemenkes RI
  static const double maxDailyFat = 67.0;
  static const int maxDailyCalories = 2000;
  static const double maxDailyCholesterol = 300.0;
  static const double maxDailyCarbs = 300.0;
  static const double maxDailyProtein = 65.0;

  // Nama kata kunci nutrisi
  static const String nutrientFat = 'Lemak';
  static const String nutrientCalories = 'Kalori';
  static const String nutrientCholesterol = 'Kolesterol';
  static const String nutrientCarbs = 'Karbohidrat';
  static const String nutrientProtein = 'Protein';

  /// Daftar lengkap seluruh nutrisi yang dipantau
  static const List<String> allNutrientKeywords = [
    nutrientFat,
    nutrientCalories,
    nutrientCholesterol,
    nutrientCarbs,
    nutrientProtein,
  ];

  // ID Notifikasi Sistem Android deterministik per kategori nutrisi
  static const int systemNotifIdMultiNutrient = 40000;
  static const int systemNotifIdFat = 40001;
  static const int systemNotifIdCalories = 40002;
  static const int systemNotifIdCholesterol = 40003;
  static const int systemNotifIdCarbs = 40004;
  static const int systemNotifIdProtein = 40005;

  /// Helper penamaan kunci preferensi SharedPreferences
  static String prefDismissedKey(int userId, String keyword) =>
      'dismissed_nutrition_${userId}_$keyword';
  static String prefDailyNotifKey(int userId, String keyword) =>
      'last_notif_nutrition_${userId}_$keyword';

  /// Memeriksa total asupan gizi hari ini dan memicu notifikasi jika melebihi batas AKG
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
      for (final kw in allNutrientKeywords) {
        await resetNutrientTracking(targetUserId, kw);
        try {
          await _db.deleteNutritionNotifications(kw, userId: targetUserId);
        } catch (_) {
          // Supresi aman jika tidak ada notifikasi yang perlu dihapus
        }
      }
      return null;
    }

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalCholesterol = 0;

    for (final log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
      totalCholesterol += ((log['cholesterol'] as num?) ?? 0.0).toDouble();
    }

    final allNutrients = {
      nutrientFat: totalFat >= maxDailyFat,
      nutrientCalories: totalCalories > maxDailyCalories,
      nutrientCholesterol: totalCholesterol > maxDailyCholesterol,
      nutrientCarbs: totalCarbs > maxDailyCarbs,
      nutrientProtein: totalProtein > maxDailyProtein,
    };

    // Smart Hysteresis: jika asupan nutrisi kembali ke zona aman (<= batas),
    // bersihkan tracking peringatan agar jika nanti naik lagi bisa diperingatkan kembali.
    for (final entry in allNutrients.entries) {
      if (!entry.value) {
        await resetNutrientTracking(targetUserId, entry.key);
        try {
          await _db.deleteNutritionNotifications(entry.key, userId: targetUserId);
        } catch (_) {
          // Supresi aman jika notifikasi belum ada di database
        }
      }
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    NotificationModel? result;
    void setResult(NotificationModel n) => result ??= n;

    final rules = [
      if (allNutrients[nutrientFat]!)
        (
          nutrientFat,
          'Peringatan Lemak Tinggi!',
          'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / ${maxDailyFat.toStringAsFixed(0)}g) telah melebihi batas anjuran harian Kemenkes (${maxDailyFat.toStringAsFixed(0)}g). Batasi gorengan & makanan berminyak.',
        ),
      if (allNutrients[nutrientCalories]!)
        (
          nutrientCalories,
          'Peringatan Kalori Berlebih!',
          'Total asupan kalori ($totalCalories kcal / $maxDailyCalories kcal) telah melebihi target harian Anda.',
        ),
      if (allNutrients[nutrientCholesterol]!)
        (
          nutrientCholesterol,
          'Peringatan Kolesterol Tinggi!',
          'Asupan kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / ${maxDailyCholesterol.toStringAsFixed(0)}mg) telah melebihi batas anjuran harian Kemenkes (${maxDailyCholesterol.toStringAsFixed(0)}mg). Batasi makanan hewani tinggi lemak dan jeroan.',
        ),
      if (allNutrients[nutrientCarbs]!)
        (
          nutrientCarbs,
          'Peringatan Karbohidrat Tinggi!',
          'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / ${maxDailyCarbs.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        ),
      if (allNutrients[nutrientProtein]!)
        (
          nutrientProtein,
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
    // satukan notifikasi sistem Android menjadi 1 ringkasan elegan agar tidak membanjiri user.
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
      } catch (e) {
        debugPrint('[NutritionService] Gagal menampilkan notifikasi sistem: $e');
      }
    } else if (newlyExceeded.length > 1) {
      final joinedNutrients = newlyExceeded.join(', ');
      try {
        await _notificationService.showSystemNotification(
          id: systemNotifIdMultiNutrient,
          title: 'Peringatan Asupan Harian: $joinedNutrients Berlebih!',
          body:
              'Asupan $joinedNutrients Anda hari ini telah melebihi batas anjuran harian. Periksa rincian menu Anda di Food Tracker.',
        );
      } catch (e) {
        debugPrint('[NutritionService] Gagal menampilkan notifikasi multi-nutrisi: $e');
      }
    }

    return result;
  }

  /// Menentukan ID notifikasi sistem Android berdasarkan kata kunci nutrisi
  static int getSystemNotifId(String keyword) {
    if (keyword.contains(nutrientFat)) return systemNotifIdFat;
    if (keyword.contains(nutrientCalories)) return systemNotifIdCalories;
    if (keyword.contains(nutrientCholesterol)) return systemNotifIdCholesterol;
    if (keyword.contains(nutrientCarbs)) return systemNotifIdCarbs;
    if (keyword.contains(nutrientProtein)) return systemNotifIdProtein;
    return systemNotifIdMultiNutrient;
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
    final dismissedKey = prefDismissedKey(userId, keyword);
    if (prefs.getString(dismissedKey) == todayDateStr) {
      return false;
    }

    // 1. Hanya kirim 1x per siklus kenaikan; jangan duplikasi jika sudah dikirim hari ini
    final dailyKey = prefDailyNotifKey(userId, keyword);
    if (prefs.getString(dailyKey) == todayDateStr) {
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
        type: NotificationModel.typeNutritionExcess,
        iconType: NotificationModel.iconWarning,
        createdAt: DateTime.now(),
      );
      final id = await _db.addNotification(notif);
      await prefs.setString(dailyKey, todayDateStr);

      if (getContainer() == null) {
        setContainer(notif.copyWith(id: id));
      }
      return true;
    } else {
      await prefs.setString(dailyKey, todayDateStr);
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
    await prefs.setString(prefDismissedKey(userId, keyword), todayDateStr);
  }

  /// Mereset tracking peringatan nutrisi ke zona aman saat asupan kembali normal
  static Future<void> resetNutrientTracking(int userId, String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefDailyNotifKey(userId, keyword));
    await prefs.remove(prefDismissedKey(userId, keyword));
  }
}
