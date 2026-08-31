import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/preference_handler.dart';
import 'views/onboarding/splash_screen.dart';

// Entry point aplikasi FoodCura
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await initializeDateFormatting('id_ID', null);
  await PreferenceHandler.init();
  await NotificationService.instance.init();
  runApp(const FoodCuraApp());
}

// Root widget aplikasi FoodCura
class FoodCuraApp extends StatelessWidget {
  const FoodCuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
