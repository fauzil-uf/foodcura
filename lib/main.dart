import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
