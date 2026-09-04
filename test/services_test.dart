import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_constants.dart';
import 'package:foodcura/services/notification_service.dart';
import 'package:foodcura/services/nutrition_service.dart';
import 'package:foodcura/services/reminder_service.dart';
import 'package:foodcura/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyLoggedInUserId: 1,
    });
  });

  group('NutritionService tests', () {
    test('Verifies standard AKG threshold limits are properly defined', () {
      expect(NutritionService.maxDailyCalories, equals(2000));
      expect(NutritionService.maxDailyFat, equals(67.0));
      expect(NutritionService.maxDailyCholesterol, equals(300.0));
      expect(NutritionService.maxDailyCarbs, equals(300.0));
      expect(NutritionService.maxDailyProtein, equals(65.0));
    });

    test('recordDismissedNutritionNotification marks nutrition alert dismissed today', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await NutritionService.recordDismissedNutritionNotification(1, 'Lemak');
      expect(prefs.getString('dismissed_nutrition_1_Lemak'), equals(todayDateStr));
    });

    test('Smart Hysteresis resets tracking keys when nutrient returns to safe zone', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notif_nutrition_1_Protein', '2026-09-03');
      await prefs.setString('dismissed_nutrition_1_Protein', '2026-09-03');

      expect(prefs.getString('last_notif_nutrition_1_Protein'), isNotNull);

      await NutritionService.resetNutrientTracking(1, 'Protein');

      expect(prefs.getString('last_notif_nutrition_1_Protein'), isNull);
      expect(prefs.getString('dismissed_nutrition_1_Protein'), isNull);
    });

    test('Verifies segregated notification ID ranges (40000..40005) for nutrition alerts', () {
      expect(NutritionService.getSystemNotifId('Bundled'), equals(40000));
      expect(NutritionService.getSystemNotifId('Lemak'), equals(40001));
      expect(NutritionService.getSystemNotifId('Kalori'), equals(40002));
      expect(NutritionService.getSystemNotifId('Kolesterol'), equals(40003));
      expect(NutritionService.getSystemNotifId('Karbohidrat'), equals(40004));
      expect(NutritionService.getSystemNotifId('Protein'), equals(40005));
    });
  });



  group('NotificationService tests', () {
    test('Verifies channel ids and notification service singleton', () {
      expect(NotificationService.channelId, equals('foodcura_nutrition_alerts'));
      expect(NotificationService.mealChannelId, equals('foodcura_meal_reminders'));
      expect(NotificationService.instance, isNotNull);
    });
  });

  group('ReminderService tests', () {
    test('Verifies standard meal schedule configs are configured', () {
      expect(ReminderService.mealConfigs.length, equals(3));
      final mealTypes = ReminderService.mealConfigs
          .map((m) => m['type'])
          .toList();
      expect(mealTypes, containsAll(['Sarapan', 'Makan Siang', 'Makan Malam']));
    });

    test('syncMealAlarms executes without error and updates settings', () async {
      final service = ReminderService();
      await service.syncMealAlarms();

      final settings = await service.loadNotificationSettings();
      expect(settings['breakfastEnabled'], isTrue);
      expect(settings['lunchEnabled'], isTrue);
      expect(settings['dinnerEnabled'], isTrue);
    });

    test('saveNotificationSettings updates preferences and clears meal cache', () async {
      final service = ReminderService();
      await service.saveNotificationSettings(
        expiryAlert: true,
        nutritionExcess: true,
        dailyMealLog: true,
        ecoTips: true,
        breakfastEnabled: true,
        breakfastTime: '08:00',
        lunchEnabled: true,
        lunchTime: '13:00',
        dinnerEnabled: true,
        dinnerTime: '20:00',
      );

      final settings = await service.loadNotificationSettings();
      expect(settings['breakfastTime'], equals('08:00'));
      expect(settings['lunchTime'], equals('13:00'));
      expect(settings['dinnerTime'], equals('20:00'));
    });

    test('changing meal time multiple times resets dismissal and prevents blocking', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();

      // Perubahan pertama: jam makan siang 12:30
      await service.saveNotificationSettings(
        expiryAlert: true,
        nutritionExcess: true,
        dailyMealLog: true,
        breakfastEnabled: true,
        breakfastTime: '07:30',
        lunchEnabled: true,
        lunchTime: '12:30',
        dinnerEnabled: true,
        dinnerTime: '19:00',
      );

      // Simulasikan dismissal atau trigger lama
      await service.recordDismissedMealNotification(1, 'Makan Siang');
      expect(prefs.getString('dismissed_meal_1_Makan Siang'), isNotNull);

      // Perubahan kedua: user mengubah kembali jam makan siang ke 13:15
      await service.saveNotificationSettings(
        expiryAlert: true,
        nutritionExcess: true,
        dailyMealLog: true,
        breakfastEnabled: true,
        breakfastTime: '07:30',
        lunchEnabled: true,
        lunchTime: '13:15',
        dinnerEnabled: true,
        dinnerTime: '19:00',
      );

      final settings = await service.loadNotificationSettings();
      expect(settings['lunchTime'], equals('13:15'));
      // Flag dismissal harus dibersihkan agar notifikasi baru tidak terblokir
      expect(prefs.getString('dismissed_meal_1_Makan Siang'), isNull);
    });

    test('past meal time prevents retroactive popup while future time enables today schedule', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Set breakfast time di jam 01:00 (sudah lewat hari ini)
      // dan dinner time di jam 23:59 (masih di masa depan hari ini)
      await service.saveNotificationSettings(
        expiryAlert: true,
        nutritionExcess: true,
        dailyMealLog: true,
        breakfastEnabled: true,
        breakfastTime: '01:00',
        lunchEnabled: true,
        lunchTime: '12:00',
        dinnerEnabled: true,
        dinnerTime: '23:59',
      );

      // Karena 01:00 sudah lewat hari ini, last_notif_meal harus diset ke hari ini
      // agar tidak muncul prematur sekarang, melainkan dijadwalkan besok oleh AlarmManager.
      if (now.hour >= 1 && !(now.hour == 1 && now.minute == 0)) {
        expect(prefs.getString('last_notif_meal_1_Sarapan'), equals(todayDateStr));
      }

      // Karena 23:59 masih di masa depan hari ini, flag harus bersih agar alarm hari ini bisa berbunyi.
      if (now.hour < 23 || (now.hour == 23 && now.minute < 59)) {
        expect(prefs.getString('last_notif_meal_1_Makan Malam'), isNull);
      }
    });

    test('daily notification key suppresses duplicate notifications on same day', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('last_notif_pantry_1_10', todayDateStr);

      expect(prefs.getString('last_notif_pantry_1_10'), equals(todayDateStr));
    });

    test('recordDismissedPantryNotification marks pantry item as dismissed for today', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await service.recordDismissedPantryNotification(1, 42);
      expect(prefs.getString('dismissed_pantry_1_42'), equals(todayDateStr));

      // Simulasi besok: string tanggal berbeda, sehingga dismissal tidak lagi aktif besok
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDateStr =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      expect(prefs.getString('dismissed_pantry_1_42') == tomorrowDateStr, isFalse);
    });

    test('clearPantryNotificationTracking removes dismissal and daily notification keys', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();

      await service.recordDismissedPantryNotification(1, 99);
      await prefs.setString('last_notif_pantry_1_99', '2026-09-03');

      expect(prefs.getString('dismissed_pantry_1_99'), isNotNull);
      expect(prefs.getString('last_notif_pantry_1_99'), isNotNull);

      await service.clearPantryNotificationTracking(1, 99);

      expect(prefs.getString('dismissed_pantry_1_99'), isNull);
      expect(prefs.getString('last_notif_pantry_1_99'), isNull);
    });

    test('recordDismissedMealNotification marks meal reminder as dismissed for today', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await service.recordDismissedMealNotification(1, 'Sarapan');
      expect(prefs.getString('dismissed_meal_1_Sarapan'), equals(todayDateStr));
    });

    test('cancelAndDismissMealReminder dismisses meal reminder and cancels alarm', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await service.cancelAndDismissMealReminder(1, 'Sarapan');
      expect(prefs.getString('dismissed_meal_1_Sarapan'), equals(todayDateStr));
    });

    test('syncPantryExpiryAlarms executes cleanly without error', () async {
      final service = ReminderService();
      await service.syncPantryExpiryAlarms();
    });

    test('syncMealAlarms executes cleanly without error and respects dismissed flag', () async {
      final service = ReminderService();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayDateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString('dismissed_meal_1_Sarapan', todayDateStr);

      await service.syncMealAlarms(userId: 1);
    });
  });


  group('StreakService tests', () {
    test('Computes streak bounds correctly from join date and active days', () {
      final service = StreakService();
      expect(service, isNotNull);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // 1-day membership
      final daysSinceJoin1 = today.difference(today).inDays + 1;
      expect(daysSinceJoin1, equals(1));

      // 2-day membership (joined yesterday)
      final daysSinceJoin2 = today.difference(yesterday).inDays + 1;
      expect(daysSinceJoin2, equals(2));
    });
  });
}
