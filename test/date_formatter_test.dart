import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_date_formatter.dart';
import 'package:foodcura/constants/app_typography.dart';
import 'package:foodcura/constants/app_colors.dart';

void main() {
  group('AppDateFormatter tests', () {
    test('parseDate handles Indonesian month names', () {
      final d1 = AppDateFormatter.parseDate('15 Agustus 2026');
      expect(d1, isNotNull);
      expect(d1!.year, 2026);
      expect(d1.month, 8);
      expect(d1.day, 15);

      final d2 = AppDateFormatter.parseDate('14 Agu 2026');
      expect(d2, isNotNull);
      expect(d2!.year, 2026);
      expect(d2.month, 8);
      expect(d2.day, 14);

      final d3 = AppDateFormatter.parseDate('1 Januari 2025');
      expect(d3, isNotNull);
      expect(d3!.year, 2025);
      expect(d3.month, 1);
      expect(d3.day, 1);
    });

    test('parseDate handles ISO strings', () {
      final d = AppDateFormatter.parseDate('2026-08-15');
      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 8);
      expect(d.day, 15);
    });

    test('formatShortDayName and formatMonthYear use Indonesian locale', () {
      final d = DateTime(2026, 8, 15); // Saturday = Sab
      expect(
        AppDateFormatter.formatShortDayName(d).toLowerCase(),
        contains('sab'),
      );
      expect(
        AppDateFormatter.formatMonthYear(d).toLowerCase(),
        contains('agustus 2026'),
      );
    });

    test('AppDateTimeExt and AppStringDateExt extensions work seamlessly', () {
      final d = DateTime(2026, 8, 15);
      expect(d.toShortDate(), equals(AppDateFormatter.formatShortDate(d)));
      expect(d.toFullDate(), equals(AppDateFormatter.formatToday(d)));
      expect(d.toMonthYear(), equals(AppDateFormatter.formatMonthYear(d)));
      expect(d.toShortDay(), equals(AppDateFormatter.formatShortDayName(d)));

      DateTime? nullDate;
      expect(nullDate.toShortDate(), equals('-'));
      expect(nullDate.toShortDate('Kosong'), equals('Kosong'));

      const strDate = '15 Agustus 2026';
      expect(strDate.toDateTime(), equals(DateTime(2026, 8, 15)));
    });
  });

  group('AppTextStyles and AppColors constants tests', () {
    test('AppTextStyles constants are available', () {
      expect(AppTextStyles.headlineLg, isNotNull);
      expect(AppTextStyles.headlineMd, isNotNull);
      expect(AppTextStyles.headlineSm, isNotNull);
      expect(AppTextStyles.bodyMd, isNotNull);
      expect(AppTextStyles.bodyMdDanger, isNotNull);
      expect(AppTextStyles.labelSm, isNotNull);
      expect(AppTextStyles.sectionHeader, isNotNull);
      expect(AppTextStyles.avatarInitial, isNotNull);
    });

    test('AppColors constants are defined', () {
      expect(AppColors.surfaceContainerLow, isNotNull);
      expect(AppColors.surfaceContainerHigh, isNotNull);
      expect(AppColors.ecoGreen, isNotNull);
      expect(AppColors.deepForest, isNotNull);
    });
  });
}
