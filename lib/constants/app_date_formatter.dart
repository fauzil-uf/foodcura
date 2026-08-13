import 'package:intl/intl.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> _monthsId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Return formatted date in Indonesian, e.g. "13 Agustus 2026"
  static String formatToday([DateTime? date]) {
    final now = date ?? DateTime.now();
    final day = now.day;
    final month = _monthsId[now.month - 1];
    final year = now.year;
    return '$day $month $year';
  }

  /// Format time as "07:30"
  static String formatTime([DateTime? date]) {
    final now = date ?? DateTime.now();
    return DateFormat('HH:mm').format(now);
  }
}
