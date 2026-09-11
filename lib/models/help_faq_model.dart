import 'package:flutter/material.dart';

/// Model item pertanyaan dan jawaban di Pusat Bantuan FAQ
class HelpFaqItem {
  final String question;
  final String answer;
  final IconData? icon;

  const HelpFaqItem({required this.question, required this.answer, this.icon});
}

/// Model kategori grup pertanyaan FAQ
class HelpFaqCategory {
  final String title;
  final IconData icon;
  final List<HelpFaqItem> items;

  const HelpFaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}
