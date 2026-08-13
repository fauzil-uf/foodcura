import 'package:intl/intl.dart';

class AppDateFormatter {
  AppDateFormatter._();

  /// Format date as "14 Agu 2026"
  static String formatShortDate([DateTime? date]) {
    final target = date ?? DateTime.now();
    try {
      return DateFormat('d MMM yyyy', 'id').format(target);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(target);
    }
  }

  /// Format date as "14 Agustus 2026"
  static String formatToday([DateTime? date]) {
    final target = date ?? DateTime.now();
    try {
      return DateFormat('d MMMM yyyy', 'id').format(target);
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(target);
    }
  }

  /// Format time as "14:30" (precise to minute)
  static String formatTime([DateTime? date]) {
    final target = date ?? DateTime.now();
    return DateFormat('HH:mm').format(target);
  }

  /// Format precise full date & time, e.g. "14 Agu 2026, 14:30"
  static String formatFullDateTime([DateTime? date]) {
    final target = date ?? DateTime.now();
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id').format(target);
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(target);
    }
  }

  /// Format relative time precise to minute with "Baru saja ditambahkan" for < 1 min
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Baru saja ditambahkan';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24 && date.day == now.day) {
      return 'Hari ini, ${formatTime(date)}';
    } else if (diff.inHours < 48 && date.day == now.subtract(const Duration(days: 1)).day) {
      return 'Kemarin, ${formatTime(date)}';
    } else {
      return formatFullDateTime(date);
    }
  }
}
