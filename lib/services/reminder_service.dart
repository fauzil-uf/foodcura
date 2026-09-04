import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/app_date_formatter.dart';
import '../database/db_helper.dart';
import '../models/food_log_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

// Service pemantau kedaluwarsa bahan pantry & reminder jam makan
class ReminderService {
  final DBHelper _db;
  final NotificationService _notificationService;

  ReminderService({DBHelper? db, NotificationService? notificationService})
    : _db = db ?? DBHelper(),
      _notificationService =
          notificationService ?? NotificationService.instance;

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
      'message':
          'Jangan lupa catat makan siangmu hari ini untuk tracking kalori.',
    },
    {
      'type': 'Makan Malam',
      'enabledKey': AppConstants.keyNotifDinnerEnabled,
      'timeKey': AppConstants.keyNotifDinnerTime,
      'defaultTime': '19:00',
      'title': 'Saatnya makan malam',
      'message':
          'Jangan lupa catat makan malammu hari ini untuk tracking kalori.',
    },
  ];

  static bool _isCheckingExpiry = false;
  static DateTime? _lastExpiryCheck;
  static bool _isCheckingMeals = false;
  static DateTime? _lastMealCheck;

  // Cek masa simpan bahan pantry & buat notifikasi
  Future<void> checkExpiryAndCreateNotifications({
    int? userId,
    bool force = false,
    int? specificItemId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true)) return;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return;

    // Mutex & debounce: Cegah race condition pemanggilan simultan dari banyak controller
    final now = DateTime.now();
    if (!force && _isCheckingExpiry) return;
    if (!force &&
        _lastExpiryCheck != null &&
        now.difference(_lastExpiryCheck!).inSeconds < 10) {
      return;
    }

    _isCheckingExpiry = true;
    _lastExpiryCheck = now;

    try {
      final db = await _db.database;
      final items = await _db.getPantryItems(userId: targetUserId);
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();

      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (var item in items) {
        if (item.id == null) continue;
        if (specificItemId != null && item.id != specificItemId) continue;
        if (item.isUsed) continue;
        final days = item.daysUntilExpiry;

        // 0. Cek apakah notifikasi untuk bahan ini sudah dihapus oleh pengguna hari ini
        final dismissedKey = 'dismissed_pantry_${targetUserId}_${item.id}';
        if (prefs.getString(dismissedKey) == todayDateStr) {
          continue;
        }

        // Hanya kirim 1x per hari; muncul lagi besok jika belum ditandai habis
        final dailyNotifKey = 'last_notif_pantry_${targetUserId}_${item.id}';
        if (prefs.getString(dailyNotifKey) == todayDateStr ||
            prefs.getString('${dailyNotifKey}_$days') == todayDateStr) {
          continue;
        }

        // 1. Peringatan Dini 1 Bulan Sebelum Kedaluwarsa (H-30 / rentang 28-30 hari)
        // Dikirim HANYA SEKALI per item agar pengguna dapat merencanakan stok jauh-jauh hari.
        if (days >= 28 && days <= 30) {
          final title = 'Pengingat 1 Bulan: ${item.name}';
          final message =
              '${item.name} di ${item.storage.toLowerCase()} akan kedaluwarsa dalam $days hari. Rencanakan penggunaannya agar tidak terbuang!';

          final h30Key = 'last_h30_pantry_${targetUserId}_${item.id}';
          if (prefs.getBool(h30Key) == true) {
            continue;
          }

          final alreadyNotified = await db.query(
            DBHelper.tableNotifications,
            where: 'related_pantry_id = ? AND user_id = ?',
            whereArgs: [item.id, targetUserId],
          );

          if (alreadyNotified.isEmpty) {
            await _db.addNotification(
              NotificationModel(
                userId: targetUserId,
                title: title,
                message: message,
                type: 'expiry_warning',
                iconType: 'lightbulb',
                relatedPantryId: item.id,
                createdAt: DateTime.now(),
              ),
            );
            await prefs.setString(dailyNotifKey, todayDateStr);
            await prefs.setBool(h30Key, true);

            // Gunakan ID deterministik per bahan agar Android meng-update notifikasi dan tidak menduplikasi kartu
            final systemNotifId = 20000 + item.id!;
            try {
              await _notificationService.showSystemNotification(
                id: systemNotifId,
                title: title,
                body: message,
              );
            } catch (_) {}
          }
        }
        // 2. Peringatan Bertahap Saat Masuk Status Segera / Urgent / Expired (H-5 s/d H+3)
        else if (days >= -3 && days <= 5) {
          final String title;
          final String message;
          if (days < 0) {
            title = 'Bahan Kedaluwarsa: ${item.name}';
            message =
                '${item.name} di ${item.storage.toLowerCase()} telah melewati batas waktu simpan. Periksa kelayakannya sebelum dikonsumsi.';
          } else if (days == 0) {
            title = 'Kedaluwarsa Hari Ini: ${item.name}';
            message =
                '${item.name} di ${item.storage.toLowerCase()} mencapai batas simpan hari ini. Segera masak atau konsumsi.';
          } else if (days == 1) {
            title = 'Kedaluwarsa Besok: ${item.name}';
            message =
                '${item.name} di ${item.storage.toLowerCase()} tersisa 1 hari lagi. Prioritaskan untuk dimasak hari ini!';
          } else if (days <= 3) {
            title = 'Mendekati Kedaluwarsa: ${item.name}';
            message =
                '${item.name} di ${item.storage.toLowerCase()} akan kedaluwarsa dalam $days hari. Rencanakan menu untuk bahan ini.';
          } else {
            title = 'Pengingat Stok: ${item.name}';
            message =
                '${item.name} di ${item.storage.toLowerCase()} memiliki sisa masa simpan $days hari lagi.';
          }

          final legacyKey = '${dailyNotifKey}_$title';
          if (prefs.getString(legacyKey) == todayDateStr) {
            continue;
          }

          // Cek di database untuk mencegah double-insert jika ada eksekusi simultan
          final existing = await db.query(
            DBHelper.tableNotifications,
            where: 'related_pantry_id = ? AND title = ? AND created_at >= ? AND user_id = ?',
            whereArgs: [item.id, title, todayStart, targetUserId],
          );

          if (existing.isEmpty) {
            await _db.addNotification(
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
            await prefs.setString(dailyNotifKey, todayDateStr);
            await prefs.setString(legacyKey, todayDateStr);

            // ID deterministik spesifik item (20000 + id bahan) menjamin 0 duplikasi di status bar Android
            final systemNotifId = 20000 + item.id!;
            try {
              await _notificationService.showSystemNotification(
                id: systemNotifId,
                title: title,
                body: message,
                channelIdOverride: days <= 0
                    ? NotificationService.urgentExpiryChannelId
                    : NotificationService.warningExpiryChannelId,
              );
            } catch (_) {}
          } else {
            await prefs.setString(dailyNotifKey, todayDateStr);
            await prefs.setString(legacyKey, todayDateStr);
          }
        }
      }
    } finally {
      _isCheckingExpiry = false;
    }
  }

  /// Mencatat bahwa notifikasi bahan pantry telah dihapus/dismissed oleh pengguna hari ini
  Future<void> recordDismissedPantryNotification(int userId, int pantryId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setString('dismissed_pantry_${userId}_$pantryId', todayDateStr);
  }

  /// Membersihkan tracking dismiss/notifikasi (misal saat bahan diedit tanggal kedaluwarsanya)
  Future<void> clearPantryNotificationTracking(int userId, int pantryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dismissed_pantry_${userId}_$pantryId');
    await prefs.remove('last_notif_pantry_${userId}_$pantryId');
  }

  /// Mengecek jadwal pengingat makan dan membuat notifikasi jika pengguna belum mencatat makanan untuk jam makan tersebut.
  Future<void> checkMealRemindersAndCreateNotifications({
    int? userId,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true)) return;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return;

    final now = DateTime.now();
    if (!force && _isCheckingMeals) return;
    if (!force &&
        _lastMealCheck != null &&
        now.difference(_lastMealCheck!).inSeconds < 10) {
      return;
    }

    _isCheckingMeals = true;
    _lastMealCheck = now;

    try {
      final targetUserId = userId ?? await _db.getActiveUserId();
      if (targetUserId != null) {
        await _db.migrateSampleFoodLogsFromToday(userId: targetUserId);
      }

      final db = await _db.database;
      final todayStr = AppDateFormatter.formatToday();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();

      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (var i = 0; i < mealConfigs.length; i++) {
        final meal = mealConfigs[i];
        if (!(prefs.getBool(meal['enabledKey']!) ?? true)) continue;

        final mealType = meal['type']!;
        // Hanya kirim 1x per hari; jangan bangkit kembali jika sudah dihapus hari ini
        final dismissedKey = 'dismissed_meal_${targetUserId}_$mealType';
        if (!force && prefs.getString(dismissedKey) == todayDateStr) continue;

        final dailyNotifKey = 'last_notif_meal_${targetUserId}_$mealType';
        if (!force && prefs.getString(dailyNotifKey) == todayDateStr) continue;

        final timeStr =
            prefs.getString(meal['timeKey']!) ?? meal['defaultTime']!;
        final parts = timeStr.split(':');
        final targetHour = int.tryParse(parts[0]) ?? 12;
        final targetMinute = parts.length > 1
            ? (int.tryParse(parts[1]) ?? 0)
            : 0;

        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          targetHour,
          targetMinute,
        );
        // Jangan pernah memicu pengingat jika waktu makan tersebut belum tiba hari ini.
        // Alarm latar belakang OS (AlarmManager) yang bertugas berbunyi saat jam makan tiba.
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
            where:
                "type = 'meal_reminder' AND (LOWER(title) LIKE ? OR LOWER(message) LIKE ?) AND created_at >= ? AND user_id = ?",
            whereArgs: [
              '%${mealType.toLowerCase()}%',
              '%${mealType.toLowerCase()}%',
              startOfDay,
              targetUserId,
            ],
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
            await _db.addNotification(notif);
            await prefs.setString(dailyNotifKey, todayDateStr);

            // ID deterministik per jadwal makan (10001, 10002, 10003)
            final systemNotifId = 10001 + i;
            try {
              await _notificationService.showSystemNotification(
                id: systemNotifId,
                title: notif.title,
                body: notif.message,
                channelIdOverride: NotificationService.mealChannelId,
              );
            } catch (_) {}
          } else {
            await prefs.setString(dailyNotifKey, todayDateStr);
          }
        }
      }
    } finally {
      _isCheckingMeals = false;
    }
  }

  /// Mencatat bahwa notifikasi pengingat jam makan telah dihapus oleh pengguna hari ini
  Future<void> recordDismissedMealNotification(int userId, String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setString('dismissed_meal_${userId}_$mealType', todayDateStr);
  }

  /// Membatalkan dan menghapus notifikasi pengingat makan saat makanan jam tersebut telah dicatat
  Future<void> cancelAndDismissMealReminder(int userId, String mealType) async {
    await recordDismissedMealNotification(userId, mealType);
    try {
      await _db.deleteMealReminderNotifications(mealType, userId: userId);
    } catch (_) {}

    int? systemNotifId;
    if (mealType.contains('Sarapan')) {
      systemNotifId = 10001;
    } else if (mealType.contains('Siang')) {
      systemNotifId = 10002;
    } else if (mealType.contains('Malam')) {
      systemNotifId = 10003;
    }

    if (systemNotifId != null) {
      try {
        await _notificationService.cancelNotification(systemNotifId);
      } catch (_) {}
      // Jadwalkan ulang mulai besok agar alarm jam makan besok dan seterusnya tetap aktif
      await rescheduleMealAlarmForTomorrow(mealType);
    }
  }

  /// Menjadwalkan ulang alarm pengingat makan tertentu mulai besok
  /// Ini memastikan pembatalan notifikasi hari ini tidak menghapus jadwal hari-hari berikutnya
  Future<void> rescheduleMealAlarmForTomorrow(String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final isMasterEnabled =
        prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true;
    if (!isMasterEnabled) return;

    for (var i = 0; i < mealConfigs.length; i++) {
      final meal = mealConfigs[i];
      if (mealType.contains(meal['type']!) || meal['type']!.contains(mealType)) {
        final isEnabled = prefs.getBool(meal['enabledKey']!) ?? true;
        final systemNotifId = 10001 + i;
        if (!isEnabled) {
          await _notificationService.cancelNotification(systemNotifId);
          return;
        }

        final timeStr =
            prefs.getString(meal['timeKey']!) ?? meal['defaultTime']!;
        final parts = timeStr.split(':');
        final targetHour = int.tryParse(parts[0]) ?? 12;
        final targetMinute =
            parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

        await _notificationService.scheduleDailyMealNotification(
          id: systemNotifId,
          title: meal['title']!,
          body: meal['message']!,
          hour: targetHour,
          minute: targetMinute,
          startFromTomorrow: true,
        );
        break;
      }
    }
  }



  /// Memuat seluruh preferensi notifikasi pengguna dari local storage
  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'expiryAlert': prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true,
      'nutritionExcess':
          prefs.getBool(AppConstants.keyNotifNutritionExcess) ?? true,
      'dailyMealLog': prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true,
      'ecoTips': prefs.getBool(AppConstants.keyNotifEcoTips) ?? true,
      'breakfastEnabled':
          prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true,
      'breakfastTime':
          prefs.getString(AppConstants.keyNotifBreakfastTime) ?? '07:30',
      'lunchEnabled': prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true,
      'lunchTime': prefs.getString(AppConstants.keyNotifLunchTime) ?? '12:30',
      'dinnerEnabled':
          prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true,
      'dinnerTime': prefs.getString(AppConstants.keyNotifDinnerTime) ?? '19:00',
    };
  }

  /// Menyimpan preferensi notifikasi pengguna dan memperbarui jadwal pengingat
  Future<void> saveNotificationSettings({
    required bool expiryAlert,
    required bool nutritionExcess,
    required bool dailyMealLog,
    bool ecoTips = false,
    required bool breakfastEnabled,
    required String breakfastTime,
    required bool lunchEnabled,
    required String lunchTime,
    required bool dinnerEnabled,
    required String dinnerTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final oldBreakfastTime = prefs.getString(AppConstants.keyNotifBreakfastTime);
    final oldLunchTime = prefs.getString(AppConstants.keyNotifLunchTime);
    final oldDinnerTime = prefs.getString(AppConstants.keyNotifDinnerTime);
    final oldBreakfastEnabled =
        prefs.getBool(AppConstants.keyNotifBreakfastEnabled) ?? true;
    final oldLunchEnabled =
        prefs.getBool(AppConstants.keyNotifLunchEnabled) ?? true;
    final oldDinnerEnabled =
        prefs.getBool(AppConstants.keyNotifDinnerEnabled) ?? true;

    await prefs.setBool(AppConstants.keyNotifExpiryAlert, expiryAlert);
    await prefs.setBool(AppConstants.keyNotifNutritionExcess, nutritionExcess);
    await prefs.setBool(AppConstants.keyNotifDailyMealLog, dailyMealLog);
    await prefs.setBool(AppConstants.keyNotifEcoTips, ecoTips);
    await prefs.setBool(
      AppConstants.keyNotifBreakfastEnabled,
      breakfastEnabled,
    );
    await prefs.setString(AppConstants.keyNotifBreakfastTime, breakfastTime);
    await prefs.setBool(AppConstants.keyNotifLunchEnabled, lunchEnabled);
    await prefs.setString(AppConstants.keyNotifLunchTime, lunchTime);
    await prefs.setBool(AppConstants.keyNotifDinnerEnabled, dinnerEnabled);
    await prefs.setString(AppConstants.keyNotifDinnerTime, dinnerTime);

    final targetUserId = await _db.getActiveUserId();
    if (targetUserId != null) {
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      Future<void> handleMealScheduleUpdate({
        required String mealType,
        required int notifId,
        required bool oldEnabled,
        required bool newEnabled,
        required String? oldTime,
        required String newTime,
      }) async {
        final timeChanged = oldTime != newTime;
        final enabledChanged = !oldEnabled && newEnabled;

        if (timeChanged || enabledChanged) {
          // 1. Batalkan alarm notifikasi sistem yang sedang berjalan untuk jadwal lama
          try {
            await _notificationService.cancelNotification(notifId);
          } catch (_) {}

          // 2. Hapus riwayat notifikasi jadwal makan ini di database hari ini agar jadwal baru tidak terblokir
          try {
            await _db.deleteMealReminderNotifications(
              mealType,
              userId: targetUserId,
            );
          } catch (e) {
            debugPrint('Failed to delete meal reminder notifications: $e');
          }

          // 3. Bersihkan flag dismiss hari ini
          await prefs.remove('dismissed_meal_${targetUserId}_$mealType');

          // 4. Periksa apakah waktu baru sudah lewat hari ini
          final parts = newTime.split(':');
          final hour = int.tryParse(parts[0]) ?? 12;
          final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final scheduledToday = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          // Jika jam yang dipilih sudah lewat hari ini (bukan menit berjalan yang sedang dites),
          // tandai agar tidak ditembakkan secara retroaktif hari ini.
          if (scheduledToday.isBefore(now) &&
              !(now.hour == hour && now.minute == minute)) {
            await prefs.setString(
              'last_notif_meal_${targetUserId}_$mealType',
              todayDateStr,
            );
          } else {
            // Jika jam masih di masa depan atau tepat di menit ini, bersihkan flag
            // agar alarm / pengecekan nanti dapat berjalan normal.
            await prefs.remove('last_notif_meal_${targetUserId}_$mealType');
          }
        } else if (!newEnabled && oldEnabled) {
          // Jika dinonaktifkan, batalkan notifikasi sistem
          try {
            await _notificationService.cancelNotification(notifId);
          } catch (_) {}
          try {
            await _db.deleteMealReminderNotifications(
              mealType,
              userId: targetUserId,
            );
          } catch (e) {
            debugPrint('Failed to delete meal reminder notifications: $e');
          }
        }
      }

      await handleMealScheduleUpdate(
        mealType: 'Sarapan',
        notifId: 10001,
        oldEnabled: oldBreakfastEnabled,
        newEnabled: breakfastEnabled,
        oldTime: oldBreakfastTime,
        newTime: breakfastTime,
      );

      await handleMealScheduleUpdate(
        mealType: 'Makan Siang',
        notifId: 10002,
        oldEnabled: oldLunchEnabled,
        newEnabled: lunchEnabled,
        oldTime: oldLunchTime,
        newTime: lunchTime,
      );

      await handleMealScheduleUpdate(
        mealType: 'Makan Malam',
        notifId: 10003,
        oldEnabled: oldDinnerEnabled,
        newEnabled: dinnerEnabled,
        oldTime: oldDinnerTime,
        newTime: dinnerTime,
      );
    }

    await syncMealAlarms();
    await syncPantryExpiryAlarms(userId: targetUserId);
  }

  /// Mensinkronkan seluruh jadwal notifikasi pengingat jam makan harian ke sistem operasi
  Future<void> syncMealAlarms({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final isMasterEnabled =
        prefs.getBool(AppConstants.keyNotifDailyMealLog) ?? true;

    final targetUserId = userId ?? await _db.getActiveUserId();
    final todayStr = AppDateFormatter.formatToday();
    final now = DateTime.now();
    final todayDateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    List<FoodLogModel> todayLogs = [];
    if (targetUserId != null) {
      try {
        todayLogs = await _db.getFoodLogs(date: todayStr, userId: targetUserId);
      } catch (_) {}
    }

    for (var i = 0; i < mealConfigs.length; i++) {
      final meal = mealConfigs[i];
      final systemNotifId = 10001 + i;

      final isEnabled =
          isMasterEnabled && (prefs.getBool(meal['enabledKey']!) ?? true);

      if (!isEnabled) {
        await _notificationService.cancelNotification(systemNotifId);
        continue;
      }

      final mealType = meal['type']!;
      bool alreadyDoneToday = false;
      if (targetUserId != null) {
        final dismissedKey = 'dismissed_meal_${targetUserId}_$mealType';
        if (prefs.getString(dismissedKey) == todayDateStr) {
          alreadyDoneToday = true;
        } else if (todayLogs.any(
          (l) => l.mealType.toLowerCase() == mealType.toLowerCase(),
        )) {
          alreadyDoneToday = true;
        }
      }

      final timeStr =
          prefs.getString(meal['timeKey']!) ?? meal['defaultTime']!;
      final parts = timeStr.split(':');
      final targetHour = int.tryParse(parts[0]) ?? 12;
      final targetMinute =
          parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      await _notificationService.scheduleDailyMealNotification(
        id: systemNotifId,
        title: meal['title']!,
        body: meal['message']!,
        hour: targetHour,
        minute: targetMinute,
        startFromTomorrow: alreadyDoneToday,
      );
    }
  }

  /// Mensinkronkan alarm pengingat kedaluwarsa per-bahan ke sistem Android OS jam 08:00.
  Future<void> syncPantryExpiryAlarms({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(AppConstants.keyNotifExpiryAlert) ?? true;

    final targetUserId = userId ?? await _db.getActiveUserId();
    if (targetUserId == null) return;

    try {
      final items = await _db.getPantryItems(userId: targetUserId);
      await _notificationService.cancelNotification(20000);

      for (final item in items) {
        final urgentId = 30000 + ((item.id ?? 0) * 10) + 1;
        final warningId = 30000 + ((item.id ?? 0) * 10) + 2;

        if (!isEnabled || item.isUsed) {
          await _notificationService.cancelNotification(urgentId);
          await _notificationService.cancelNotification(warningId);
          continue;
        }

        final days = item.daysUntilExpiry;

        if (days < -3) {
          await _notificationService.cancelNotification(urgentId);
          await _notificationService.cancelNotification(warningId);
        } else if (days < 0) {
          await _notificationService.cancelNotification(warningId);
          await _notificationService.scheduleDailyExpiryNotification(
            id: urgentId,
            title: 'Bahan Kedaluwarsa: ${item.name}',
            body:
                '${item.name} di ${item.storage.toLowerCase()} telah melewati batas waktu simpan. Periksa kelayakannya sebelum dikonsumsi.',
            hour: 8,
            minute: 0,
            channelId: NotificationService.urgentExpiryChannelId,
          );
        } else if (days <= 1) {
          await _notificationService.cancelNotification(warningId);
          await _notificationService.scheduleDailyExpiryNotification(
            id: urgentId,
            title: days == 0
                ? 'Kedaluwarsa Hari Ini: ${item.name}'
                : 'Kedaluwarsa Besok: ${item.name}',
            body: days == 0
                ? '${item.name} di ${item.storage.toLowerCase()} mencapai batas simpan hari ini. Segera masak atau konsumsi.'
                : '${item.name} di ${item.storage.toLowerCase()} tersisa 1 hari lagi. Prioritaskan untuk dimasak hari ini!',
            hour: 8,
            minute: 0,
            channelId: NotificationService.urgentExpiryChannelId,
          );
        } else if (days <= 5) {
          await _notificationService.cancelNotification(urgentId);
          await _notificationService.scheduleDailyExpiryNotification(
            id: warningId,
            title: days <= 3
                ? 'Mendekati Kedaluwarsa: ${item.name}'
                : 'Pengingat Stok: ${item.name}',
            body:
                '${item.name} di ${item.storage.toLowerCase()} akan kedaluwarsa dalam $days hari. Rencanakan menu untuk bahan ini.',
            hour: 8,
            minute: 0,
            channelId: NotificationService.warningExpiryChannelId,
          );
        } else {
          await _notificationService.cancelNotification(urgentId);
          await _notificationService.cancelNotification(warningId);
        }
      }
    } catch (e) {
      debugPrint('Failed to sync pantry expiry alarms: $e');
    }
  }
}
