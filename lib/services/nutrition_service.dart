import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service untuk evaluasi batas gizi harian (AKG Kemenkes) dan pemicu notifikasi kelebihan nutrisi.
class NutritionService {
  final DBHelper _db;
  final NotificationService _notificationService;

  NutritionService({DBHelper? db, NotificationService? notificationService})
      : _db = db ?? DBHelper(),
        _notificationService = notificationService ?? NotificationService.instance;

  static const double maxDailyFat = 67.0;
  static const int maxDailyCalories = 2000;
  static const double maxDailyCholesterol = 300.0;
  static const double maxDailyCarbs = 300.0;
  static const double maxDailyProtein = 65.0;

  /// Mengevaluasi log makanan hari ini dan mengirim notifikasi jika melampaui batas AKG.
  Future<NotificationModel?> checkNutritionExcess({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true)) return null;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return null;

    final db = await _db.database;
    final todayStr = AppDateFormatter.formatToday();
    final logs = await db.query(
      DBHelper.tableFoodLogs,
      where: 'date = ? AND user_id = ?',
      whereArgs: [todayStr, targetUserId],
    );
    if (logs.isEmpty) return null;

    int totalCalories = 0;
    double totalProtein = 0, totalCarbs = 0, totalFat = 0, totalCholesterol = 0;
    for (var log in logs) {
      totalCalories += (log['calories'] as num).toInt();
      totalProtein += (log['protein'] as num).toDouble();
      totalCarbs += (log['carbs'] as num).toDouble();
      totalFat += (log['fat'] as num).toDouble();
      totalCholesterol += ((log['cholesterol'] as num?) ?? 0.0).toDouble();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    NotificationModel? result;
    void setResult(NotificationModel n) => result ??= n;

    final rules = [
      if (totalFat >= maxDailyFat)
        (
          'Lemak',
          'Peringatan Lemak Tinggi!',
          'Asupan Lemak (${totalFat.toStringAsFixed(1)}g / ${maxDailyFat.toStringAsFixed(0)}g) telah melebihi batas anjuran harian Kemenkes (67g). Batasi gorengan & makanan berminyak.',
        ),
      if (totalCalories > maxDailyCalories)
        (
          'Kalori',
          'Peringatan Kalori Berlebih!',
          'Total asupan kalori ($totalCalories kcal / $maxDailyCalories kcal) telah melebihi target harian Anda.',
        ),
      if (totalCholesterol > maxDailyCholesterol)
        (
          'Kolesterol',
          'Peringatan Kolesterol Tinggi!',
          'Asupan kolesterol (${totalCholesterol.toStringAsFixed(0)}mg / ${maxDailyCholesterol.toStringAsFixed(0)}mg) telah melebihi batas anjuran harian Kemenkes (300mg). Batasi makanan hewani tinggi lemak dan jeroan.',
        ),
      if (totalCarbs > maxDailyCarbs)
        (
          'Karbohidrat',
          'Peringatan Karbohidrat Tinggi!',
          'Asupan Karbohidrat (${totalCarbs.toStringAsFixed(1)}g / ${maxDailyCarbs.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        ),
      if (totalProtein > maxDailyProtein)
        (
          'Protein',
          'Peringatan Protein Tinggi!',
          'Asupan Protein (${totalProtein.toStringAsFixed(1)}g / ${maxDailyProtein.toStringAsFixed(0)}g) telah melebihi rekomendasi harian.',
        ),
    ];

    for (final rule in rules) {
      await _checkAndNotify(
        keyword: rule.$1,
        startOfDay: startOfDay,
        title: rule.$2,
        message: rule.$3,
        getContainer: () => result,
        setContainer: setResult,
        userId: targetUserId,
      );
    }
    return result;
  }

  Future<void> _checkAndNotify({
    required String keyword,
    required String startOfDay,
    required String title,
    required String message,
    required NotificationModel? Function() getContainer,
    required void Function(NotificationModel) setContainer,
    required int userId,
  }) async {
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
      try {
        await _notificationService.showSystemNotification(
          id: id,
          title: notif.title,
          body: notif.message,
        );
      } catch (_) {}
      if (getContainer() == null) {
        setContainer(notif.copyWith(id: id));
      }
    }
  }
}
