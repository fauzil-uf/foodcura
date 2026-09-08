import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_typography.dart';
import 'package:foodcura/constants/app_theme.dart';

import 'package:foodcura/views/profile/help_center_screen.dart';
import 'package:foodcura/views/profile/widgets/about_foodcura_dialog.dart'
    as foodcura_about;
import 'package:foodcura/views/widgets/app_wheel_time_picker.dart';
import 'package:foodcura/views/widgets/app_food_image.dart';
import 'package:foodcura/views/widgets/app_shimmer.dart';
import 'package:foodcura/views/widgets/app_connectivity_banner.dart';
import 'package:foodcura/services/connectivity_service.dart';
import 'package:foodcura/views/onboarding/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodcura/services/preference_handler.dart';

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

    expect(find.text('FoodCura v2.3.1'), findsOneWidget);
    expect(find.text('Lihat Lisensi Open Source'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
  });

  testWidgets('AppWheelTimePickerSheet renders and selects preset time correctly', (
    WidgetTester tester,
  ) async {
    String? selectedResult;

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedResult = await AppWheelTimePickerSheet.show(
                  context: context,
                  initialTime: '07:30',
                  title: 'Atur Waktu Sarapan',
                  presets: ['06:30', '07:00', '07:30', '08:00'],
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open sheet
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify Title & Initial Time Display
    expect(find.text('Atur Waktu Sarapan'), findsOneWidget);
    expect(find.text('07:30 WIB'), findsOneWidget);
    expect(find.text('06:30'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);

    // Tap preset '08:00'
    await tester.tap(find.text('08:00'));
    await tester.pumpAndSettle();

    // Verify time display updated
    expect(find.text('08:00 WIB'), findsOneWidget);

    // Tap 'Terapkan'
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();

    expect(selectedResult, equals('08:00'));
  });

  testWidgets('SplashScreen renders logo, typography and tagline properly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await PreferenceHandler.init();

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(RichText), findsWidgets);

    // Advance clock past the remaining timers to let the animation complete
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('AppFoodImage renders fallback when path is null or empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFoodImage(
            imagePath: null,
            fallbackIcon: Icons.restaurant_rounded,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });

  testWidgets('AppFoodImage renders cached network image widget for online URLs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFoodImage(
            imagePath: 'https://images.unsplash.com/photo-example.jpg',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );

    expect(find.byType(AppFoodImage), findsOneWidget);
  });

  testWidgets('AppShimmer and AppShimmerCard render properly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppShimmer(child: Text('Shimmering Text')),
              AppShimmerBox(width: 100, height: 20),
              AppShimmerCard(),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsWidgets);
    expect(find.byType(AppShimmerBox), findsWidgets);
    expect(find.byType(AppShimmerCard), findsOneWidget);
  });

  testWidgets('AppConnectivityBanner responds to online/offline state transitions', (
    WidgetTester tester,
  ) async {
    // Start with online state
    ConnectivityService.instance.setMockOnline(true);

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Center(child: Text('Main Content'))),
        builder: (context, child) => AppConnectivityBanner(child: child!),
      ),
    );
    await tester.pump();

    // Verify main content is visible
    expect(find.text('Main Content'), findsOneWidget);

    // Simulate going offline
    ConnectivityService.instance.setMockOnline(false);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Anda sedang offline • Berjalan dalam mode lokal'), findsOneWidget);

    // Simulate coming back online
    ConnectivityService.instance.setMockOnline(true);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Koneksi pulih • Sinkronisasi & AI aktif'), findsOneWidget);

    // Advance past dismiss timer
    await tester.pump(const Duration(seconds: 4));
  });
}
