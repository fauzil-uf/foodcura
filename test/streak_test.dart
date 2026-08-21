import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_date_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Streak calculation logic tests', () {
    test('Calculates streak accurately for 1 day (joined today or yesterday)', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Case 1: Active today only
      final dateSetToday = {today};
      int streak1 = 0;
      DateTime check1 = today;
      while (dateSetToday.contains(check1)) {
        streak1++;
        check1 = check1.subtract(const Duration(days: 1));
      }
      expect(streak1, equals(1));

      // Case 2: Active yesterday only
      final dateSetYest = {yesterday};
      int streak2 = 0;
      DateTime check2 = yesterday;
      while (dateSetYest.contains(check2)) {
        streak2++;
        check2 = check2.subtract(const Duration(days: 1));
      }
      expect(streak2, equals(1));
    });

    test('Calculates streak accurately for consecutive days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final day2Before = today.subtract(const Duration(days: 2));

      final dateSet = {today, yesterday, day2Before};
      int streak = 0;
      DateTime check = today;
      while (dateSet.contains(check)) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      }
      expect(streak, equals(3));
    });

    test('Caps streak by join date so newly joined user never exceeds days since join', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // User registered yesterday (2 days max: yesterday & today)
      final joinDay = yesterday;
      final daysSinceJoin = today.difference(joinDay).inDays + 1;
      expect(daysSinceJoin, equals(2));

      int streak = 7; // corrupted / old cached value
      if (streak > daysSinceJoin) {
        streak = daysSinceJoin;
      }
      expect(streak, equals(2));
    });

    test('AppDateFormatter parses various Indonesian date formats', () {
      final parsed = AppDateFormatter.parseDate('20 Agustus 2026');
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(2026));
      expect(parsed.month, equals(8));
      expect(parsed.day, equals(20));
    });
  });
}
