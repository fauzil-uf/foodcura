import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_typography.dart';
import 'package:foodcura/constants/app_theme.dart';

import 'package:foodcura/views/profile/help_center_screen.dart';
import 'package:foodcura/views/profile/widgets/about_foodcura_dialog.dart'
    as foodcura_about;

void main() {
  testWidgets('Theme and typography loads properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: Text('Profil', style: AppTextStyles.headlineLg)),
        ),
      ),
    );

    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets(
    'HelpCenterScreen renders sections, FAQs, search bar, and contact button',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
      await tester.pumpAndSettle();

      // Verify Title and Greeting
      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(find.text('Halo, ada yang bisa\nkami bantu?'), findsOneWidget);

      // Verify Search bar
      expect(find.byType(TextField), findsOneWidget);

      // Verify Categories
      expect(find.text('PERTANYAAN UMUM'), findsOneWidget);
      expect(find.text('NUTRISI'), findsOneWidget);
      expect(find.text('FOOD WASTE'), findsOneWidget);
      expect(find.text('AKUN & KEAMANAN'), findsOneWidget);

      // Verify Sample Questions
      expect(find.text('Bagaimana cara menggunakan FoodCura?'), findsOneWidget);
      expect(find.text('Bagaimana cara mencatat makanan?'), findsOneWidget);
      expect(find.text('Dari mana data nutrisi FoodCura?'), findsOneWidget);
      expect(
        find.text('Bagaimana cara FoodCura membantu mengurangi food waste?'),
        findsOneWidget,
      );
      expect(find.text('Bagaimana cara mengubah data profil?'), findsOneWidget);

      // Verify Still Need Help Section
      expect(find.text('MASIH BUTUH BANTUAN?'), findsOneWidget);
      expect(find.text('Hubungi Kami'), findsOneWidget);

      // Test Search filter
      await tester.enterText(find.byType(TextField), 'kedaluwarsa');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('hasil pencarian untuk "kedaluwarsa"'),
        findsOneWidget,
      );
    },
  );

  testWidgets('AboutFoodCuraDialog renders app version and license button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Test Dialog'))),
      ),
    );

    final BuildContext context = tester.element(find.text('Test Dialog'));
    showDialog(
      context: context,
      builder: (_) => const foodcura_about.AboutFoodCuraDialog(),
    );
    await tester.pumpAndSettle();

    expect(find.text('FoodCura v2.1.0'), findsOneWidget);
    expect(find.text('Lihat Lisensi Open Source'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
  });
}
