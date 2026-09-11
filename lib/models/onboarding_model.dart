import 'package:flutter/material.dart';

/// Model data slide pengenalan fitur aplikasi (Onboarding)
class OnboardingItem {
  final String image;
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingItem({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}
