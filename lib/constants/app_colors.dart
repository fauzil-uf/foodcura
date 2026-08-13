import 'package:flutter/material.dart';

/// Palet warna terpusat FoodCura.
/// Diambil dari 3 desain HTML (Login #1a4328, Register #123e29/#145c38,
/// Forgot Password #1b4d2e) — disatukan jadi satu sumber kebenaran (single
/// source of truth) sesuai prinsip di Flutter Fondasi Project.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF1A4328); // Dark Forest Green (brand-green)
  static const primaryDark = Color(0xFF13321D);
  static const primaryLight = Color(0xFF72A055); // logo light green

  static const background = Color(0xFFFCFBF8); // warm oatmeal background
  static const surfaceCard = Color(0xFFF7F3E8); // card register/forgot bg
  static const inputFill = Color(0xFFFFFFFF);
  static const inputFillSoft = Color(0xFFFAF8F1);

  static const textPrimary = Color(0xFF1A1C19);
  static const textGray = Color(0xFF6B7280);
  static const textGraySoft = Color(0xFF626B66);

  static const border = Color(0xFFCACACA);
  static const borderSoft = Color(0x33BEB49C); // rgba(190,180,156,.34)

  static const infoContainer = Color(0xFFE8F3EA);
  static const iconCircleBg = Color(0xFFD8EADB);

  static const error = Color(0xFFDC2626);
  static const white = Color(0xFFFFFFFF);

  // Pantry & Notification colors (from Stitch design)
  static const urgent = Color(0xFFD95338);
  static const segera = Color(0xFFE68A2E);
  static const ecoGreen = Color(0xFF347A4B);
  static const deepForest = Color(0xFF0F2C1B);
  static const mintTint = Color(0xFFE4F0E8);
  static const surfaceDim = Color(0xFFDBDAD4);
  static const surfaceContainer = Color(0xFFEFEEE8);
  static const glassSurface = Color(0xBFFFFFFF); // 75% opacity white
  static const warningBg = Color(0xFFFDE9E5);
  static const warningBorder = Color(0xFFFFD8C2);
  static const warningBgLight = Color(0xFFFFF4ED);
}
