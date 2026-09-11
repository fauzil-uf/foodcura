import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'database/db_helper.dart';
import 'firebase_options.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'services/preference_handler.dart';
import 'views/onboarding/splash_screen.dart';
import 'views/widgets/app_connectivity_banner.dart';

/// Entry point aplikasi FoodCura
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[main] Inisialisasi Firebase gagal: $e');
  }
  await initializeDateFormatting('id', null);
  await initializeDateFormatting('id_ID', null);
  await PreferenceHandler.init();
  await NotificationService.instance.init();
  try {
    await ConnectivityService.instance.init();
  } catch (e) {
    debugPrint('[main] Inisialisasi ConnectivityService gagal: $e');
  }
  // Sinkronisasi katalog makanan Firestore di background setelah UI ter-render
  Future.delayed(const Duration(seconds: 3), () {
    DBHelper().syncFoodCatalogWithFirestore().ignore();
  });
  runApp(const FoodCuraApp());
}

//// Root widget aplikasi FoodCura
class FoodCuraApp extends StatelessWidget {
  const FoodCuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) {
        return AppConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
