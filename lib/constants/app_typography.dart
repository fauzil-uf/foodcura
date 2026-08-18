import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Preset TextStyle terpusat — font "Plus Jakarta Sans" sesuai HTML.
/// Font di-bundle langsung sebagai asset lokal (assets/fonts/), lihat
/// pendaftarannya di pubspec.yaml -> flutter: fonts:.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'PlusJakartaSans';

  static TextStyle get _base => const TextStyle(fontFamily: fontFamily);

  static TextStyle get heading1 => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );

  static TextStyle get heading2 => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.7,
  );

  static TextStyle get subtitle => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textGray,
    height: 1.5,
  );

  static TextStyle get subtitleSmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textGraySoft,
    height: 1.55,
  );

  static TextStyle get body => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputText => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputTextSmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get label => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static TextStyle get logo => _base.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static TextStyle get button => _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get buttonSmall => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get linkBold => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // Stitch Design Typography Tokens
  static TextStyle get headlineLg => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.deepForest,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMd => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSm => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMd => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMdDanger => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.errorText,
  );

  static TextStyle get labelSm => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textGraySoft,
  );

  static TextStyle get sectionHeader => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textGraySoft,
    letterSpacing: 1.2,
  );

  static TextStyle get avatarInitial => _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
  );

  static TextStyle get navLabel => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textGray,
  );

  static TextStyle get navLabelActive => _base.copyWith(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle get chipText =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle get badgeText =>
      _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textGray,
  );

  static TextStyle get caption => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textGraySoft,
  );
}
