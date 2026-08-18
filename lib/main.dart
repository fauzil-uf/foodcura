import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'services/notification_service.dart';
import 'views/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.instance.init();
  runApp(const FoodCuraApp());
}

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
