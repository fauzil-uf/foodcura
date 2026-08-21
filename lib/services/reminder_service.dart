import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service untuk memantau tanggal kedaluwarsa stok pantry dan memicu pengingat jam makan harian.
class ReminderService {
  final DBHelper _db;
  final NotificationService _notificationService;

  ReminderService({DBHelper? db, NotificationService? notificationService})
      : _db = db ?? DBHelper(),
        _notificationService = notificationService ?? NotificationService.instance;

  static const List<Map<String, String>> mealConfigs = [
    {
      'type': 'Sarapan',
      'enabledKey': AppConstants.keyNotifBreakfastEnabled,
      'timeKey': AppConstants.keyNotifBreakfastTime,
      'defaultTime': '07:30',
      'title': 'Saatnya sarapan',
      'message': 'Jangan lupa catat sarapanmu hari ini untuk tracking kalori.',
    },
    {
      'type': 'Makan Siang',
      'enabledKey': AppConstants.keyNotifLunchEnabled,
      'timeKey': AppConstants.keyNotifLunchTime,
      'defaultTime': '12:30',
      'title': 'Saatnya makan siang',
      'message': 'Jangan lupa catat makan siangmu hari ini untuk tracking kalori.',
    },
    {
      'type': 'Makan Malam',
      'enabledKey': AppConstants.keyNotifDinnerEnabled,
      'timeKey': AppConstants.keyNotifDinnerTime,
      'defaultTime': '19:00',
      'title': 'Saatnya makan malam',
      'message': 'Jangan lupa catat makan malammu hari ini untuk tracking kalori.',
    },
  ];

  /// Mengecek stok pantry dan membuat notifikasi jika ada bahan yang mendekati atau melewati masa simpan.
  Future<void> checkExpiryAndCreateNotifications({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true)) return;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return;

    final db = await _db.database;
    final items = await _db.getPantryItems(userId: targetUserId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    for (var item in items) {
      final days = item.daysUntilExpiry;
      if (days <= 5) {
        final title = days <= 0
            ? '${item.name} sudah kadaluwarsa!'
            : days <= 2
                ? '${item.name} hampir kadaluwarsa'
                : '${item.name} perlu segera digunakan';
        final message = days <= 0
            ? '${item.name} di ${item.storage.toLowerCase()} sudah melewati tanggal kadaluwarsa.'
            : '${item.name} di ${item.storage.toLowerCase()} akan kadaluwarsa dalam $days hari.';

        final existing = await db.query(
          DBHelper.tableNotifications,
          where: 'related_pantry_id = ? AND title = ? AND created_at >= ? AND user_id = ?',
          whereArgs: [item.id, title, todayStart, targetUserId],
        );

        if (existing.isEmpty) {
          final id = await _db.addNotification(
            NotificationModel(
              userId: targetUserId,
              title: title,
              message: message,
              type: 'expiry_warning',
              iconType: 'warning',
              relatedPantryId: item.id,
              createdAt: DateTime.now(),
            ),
          );
          try {
            await _notificationService.showSystemNotification(
              id: id,
              title: title,
              body: message,
            );
          } catch (_) {}
        }
      }
    }
  }

  /// Mengecek jadwal pengingat makan dan membuat notifikasi jika pengguna belum mencatat makanan untuk jam makan tersebut.
  Future<void> checkMealRemindersAndCreateNotifications({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true)) return;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return;

    final db = await _db.database;
    final now = DateTime.now();
    final todayStr = AppDateFormatter.formatToday();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

    for (final meal in mealConfigs) {
      if (!(prefs.getBool(meal['enabledKey']!) ?? true)) continue;

      final timeStr = prefs.getString(meal['timeKey']!) ?? meal['defaultTime']!;
      final parts = timeStr.split(':');
      final targetHour = int.tryParse(parts[0]) ?? 12;
      final targetMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      final scheduledTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      if (now.isBefore(scheduledTime)) continue;

      final logs = await db.query(
        DBHelper.tableFoodLogs,
        where: 'date = ? AND meal_type = ? AND user_id = ?',
        whereArgs: [todayStr, meal['type']!, targetUserId],
      );

      if (logs.isEmpty) {
        final title = meal['title']!;
        final existing = await db.query(
          DBHelper.tableNotifications,
          where: 'type = ? AND title = ? AND created_at >= ? AND user_id = ?',
          whereArgs: ['meal_reminder', title, startOfDay, targetUserId],
        );

        if (existing.isEmpty) {
          final notif = NotificationModel(
            userId: targetUserId,
            title: title,
            message: meal['message']!,
            type: 'meal_reminder',
            iconType: 'restaurant',
            createdAt: now,
          );
          final id = await _db.addNotification(notif);
          try {
            await _notificationService.showSystemNotification(
              id: id,
              title: notif.title,
              body: notif.message,
            );
          } catch (_) {}
        }
      }
    }
  }

  /// Memuat seluruh preferensi notifikasi pengguna dari local storage
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'expiryAlert': prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true,
      'nutritionExcess': prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true,
      'dailyMealLog': prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true,
      'ecoTips': prefs.getBool(AppConstants.keyNotifEcoTips) ?? true,
      'breakfastEnabled': prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true,
      'breakfastTime': prefs.getString(AppConstants.keyNotifBreakfastTime) ?? '07:30',
      'lunchEnabled': prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true,
      'lunchTime': prefs.getString(AppConstants.keyNotifLunchTime) ?? '12:30',
      'dinnerEnabled': prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true,
      'dinnerTime': prefs.getString(AppConstants.keyNotifDinnerTime) ?? '19:00',
    };
  }

  /// Menyimpan preferensi notifikasi pengguna dan memperbarui jadwal pengingat
  Future<void> saveNotificationSettings({
    required bool expiryAlert,
    required bool nutritionExcess,
    required bool dailyMealLog,
    required bool ecoTips,
    required bool breakfastEnabled,
    required String breakfastTime,
    required bool lunchEnabled,
    required String lunchTime,
    required bool dinnerEnabled,
    required String dinnerTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotifExpiryAlert, expiryAlert);
    await prefs.setBool(AppConstants.keyNotifNutritionExcess, nutritionExcess);
    await prefs.setBool(AppConstants.keyNotifDailyMealLog, dailyMealLog);
    await prefs.setBool(AppConstants.keyNotifEcoTips, ecoTips);
    await prefs.setBool(AppConstants.keyNotifBreakfastEnabled, breakfastEnabled);
    await prefs.setString(AppConstants.keyNotifBreakfastTime, breakfastTime);
    await prefs.setBool(AppConstants.keyNotifLunchEnabled, lunchEnabled);
    await prefs.setString(AppConstants.keyNotifLunchTime, lunchTime);
    await prefs.setBool(AppConstants.keyNotifDinnerEnabled, dinnerEnabled);
    await prefs.setString(AppConstants.keyNotifDinnerTime, dinnerTime);

    await checkMealRemindersAndCreateNotifications();
  }
}
