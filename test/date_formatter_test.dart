import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_colors.dart';
import 'package:foodcura/constants/app_constants.dart';
import 'package:foodcura/constants/app_date_formatter.dart';
import 'package:foodcura/constants/app_food_formatter.dart';
import 'package:foodcura/constants/app_typography.dart';

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
      expect(AppColors.nutritionViolet, isNotNull);
      expect(AppColors.nutritionVioletBg, isNotNull);
    });

    test('AppConstants version is synchronized with v2.3.6 release', () {
      expect(AppConstants.appName, equals('FoodCura'));
      expect(AppConstants.appVersion, equals('2.3.6'));
      expect(AppConstants.appBuildNumber, equals('15'));
      expect(AppConstants.appVersionDisplay, equals('v2.3.6'));
    });
  });

  group('AppFoodFormatter tests', () {
    test(
      'formatFoodWithPortion scales unit and eliminates double brackets',
      () {
        expect(
          AppFoodFormatter.formatFoodWithPortion('Es Teh Tawar (1 gelas)', 1.5),
          equals('Es Teh Tawar (1.5 gelas)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion('Bihun Goreng (1 porsi)', 2.0),
          equals('Bihun Goreng (2 porsi)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Usus Ayam Goreng (1 porsi / 40g)',
            2.0,
          ),
          equals('Usus Ayam Goreng (2 porsi / 80g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion('Bayam Segar', 1.5),
          equals('Bayam Segar (1.5 porsi)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion('Martabak (Manis)', 2.0),
          equals('Martabak (Manis) (2 porsi)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Bakwan Sayur (Bala-bala) (1 buah)',
            2.0,
          ),
          equals('Bakwan Sayur (Bala-bala) (2 buah)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion('Es Teh Tawar (1 gelas)', 1.0),
          equals('Es Teh Tawar (1 gelas)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Gula Pasir (1 sdm / 13g)',
            2.0,
          ),
          equals('Gula Pasir (2 sdm / 26g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Minyak Ikan / Fish Oil (1 sdt / 5ml)',
            2.0,
          ),
          equals('Minyak Ikan / Fish Oil (2 sdt / 10ml)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Kacang Tanah Goreng (1 genggam / 28g)',
            1.5,
          ),
          equals('Kacang Tanah Goreng (1.5 genggam / 42g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Kerupuk Urat (1 bungkus kecil / 15g)',
            2.0,
          ),
          equals('Kerupuk Urat (2 bungkus kecil / 30g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Beras Putih (Mentah / 100g)',
            2.0,
          ),
          equals('Beras Putih (Mentah / 200g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Abon Ikan Haruan (1 sdm / 15g)',
            2.0,
          ),
          equals('Abon Ikan Haruan (2 sdm / 30g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Keju Cheddar Olahan (1 lembar / 20g)',
            2.0,
          ),
          equals('Keju Cheddar Olahan (2 lembar / 40g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Coklat Batang Manis (3 kotak / 25g)',
            2.0,
          ),
          equals('Coklat Batang Manis (6 kotak / 50g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Mozzarella Cheese Sticks (3 stick / 60g)',
            2.0,
          ),
          equals('Mozzarella Cheese Sticks (6 stick / 120g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Crispy Chicken Strip (3 strip / 75g)',
            2.0,
          ),
          equals('Crispy Chicken Strip (6 strip / 150g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Brem Madiun (1 lempeng)',
            2.0,
          ),
          equals('Brem Madiun (2 lempeng)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Gula Pasir (1 sdm / 13g)',
            0.0,
          ),
          equals('Gula Pasir (1 sdm / 13g)'),
        );
        expect(
          AppFoodFormatter.formatFoodWithPortion(
            'Gula Pasir (1 sdm / 13g)',
            -1.0,
          ),
          equals('Gula Pasir (1 sdm / 13g)'),
        );
      },
    );

    test('cleanDisplayName sanitizes legacy double-bracket food names', () {
      expect(
        AppFoodFormatter.cleanDisplayName('Es Teh Tawar (1 gelas) (1.5 porsi)'),
        equals('Es Teh Tawar (1.5 gelas)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName('Bihun Goreng (1 porsi) (2 porsi)'),
        equals('Bihun Goreng (2 porsi)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName(
          'Usus Ayam Goreng (1 porsi / 40g) (2 porsi)',
        ),
        equals('Usus Ayam Goreng (2 porsi / 80g)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName(
          'Bakwan Sayur (Bala-bala) (1 buah) (2 porsi)',
        ),
        equals('Bakwan Sayur (Bala-bala) (2 buah)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName('Bakwan Sayur (Bala-bala) (1 buah)'),
        equals('Bakwan Sayur (Bala-bala) (1 buah)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName('Martabak (Manis)'),
        equals('Martabak (Manis)'),
      );
      expect(
        AppFoodFormatter.cleanDisplayName('Nasi Putih (1 porsi)'),
        equals('Nasi Putih (1 porsi)'),
      );
    });
  });
}
