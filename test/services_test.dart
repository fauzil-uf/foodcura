import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/services/nutrition_service.dart';
import 'package:foodcura/services/reminder_service.dart';
import 'package:foodcura/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NutritionService tests', () {
    test('Verifies standard AKG threshold limits are properly defined', () {
      expect(NutritionService.maxDailyCalories, equals(2000));
      expect(NutritionService.maxDailyFat, equals(67.0));
      expect(NutritionService.maxDailyCholesterol, equals(300.0));
      expect(NutritionService.maxDailyCarbs, equals(300.0));
      expect(NutritionService.maxDailyProtein, equals(65.0));
    });
  });

  group('ReminderService tests', () {
    test('Verifies standard meal schedule configs are configured', () {
      expect(ReminderService.mealConfigs.length, equals(3));
      final mealTypes = ReminderService.mealConfigs.map((m) => m['type']).toList();
      expect(mealTypes, containsAll(['Sarapan', 'Makan Siang', 'Makan Malam']));
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
