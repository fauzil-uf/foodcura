import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Utilitas formatting dan parsing tanggal/waktu standar Indonesia murni menggunakan package intl.
class AppDateFormatter {
  AppDateFormatter._();

  static bool _initialized = false;
  static void _ensureInitialized() {
    if (!_initialized) {
      initializeDateFormatting('id', null);
      initializeDateFormatting('id_ID', null);
      _initialized = true;
    }
  }

  /// Format date as "14 Agu 2026"
  static String formatShortDate([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('d MMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format date as "14 Agustus 2026"
  static String formatToday([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('d MMMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format date with full day name as "Sabtu, 15 Agu 2026"
  static String formatDayDate([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('EEEE, d MMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format date as "Agustus 2026"
  static String formatMonthYear([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('MMMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format short day name as "Sen", "Sel", "Rab", etc. using locale 'id'
  static String formatShortDayName([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('EEE', 'id').format(date ?? DateTime.now());
  }

  /// Format time as "14:30" (precise to minute)
  static String formatTime([DateTime? date]) =>
      DateFormat('HH:mm').format(date ?? DateTime.now());

  /// Format precise full date & time, e.g. "14 Agu 2026, 14:30"
  static String formatFullDateTime([DateTime? date]) {
    _ensureInitialized();
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(date ?? DateTime.now());
  }

  /// Format relative time precise to minute with "Baru saja ditambahkan" for < 1 min
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Baru saja ditambahkan';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24 && date.day == now.day) {
      return 'Hari ini, ${formatTime(date)}';
    }
    if (diff.inHours < 48 &&
        date.day == now.subtract(const Duration(days: 1)).day) {
      return 'Kemarin, ${formatTime(date)}';
    }
    return formatFullDateTime(date);
  }

  static const Map<String, int> _indonesianMonths = {
    'januari': 1,
    'jan': 1,
    'january': 1,
    'februari': 2,
    'feb': 2,
    'february': 2,
    'maret': 3,
    'mar': 3,
    'march': 3,
    'april': 4,
    'apr': 4,
    'mei': 5,
    'may': 5,
    'juni': 6,
    'jun': 6,
    'june': 6,
    'juli': 7,
    'jul': 7,
    'july': 7,
    'agustus': 8,
    'agu': 8,
    'ags': 8,
    'aug': 8,
    'august': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'oktober': 10,
    'okt': 10,
    'oct': 10,
    'october': 10,
    'november': 11,
    'nov': 11,
    'desember': 12,
    'des': 12,
    'dec': 12,
    'december': 12,
  };

  /// Parse string tanggal ke [DateTime] (normalisasi ke jam 00:00:00).
  /// Mendukung format Bahasa Indonesia ("15 Agustus 2026", "14 Agu 2026"),
  /// ISO ("2026-08-15"), dan berbagai format separator.
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final clean = dateStr.trim();

    // 1. Coba ISO format standar
    final iso = DateTime.tryParse(clean);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    // 2. Parsing manual kata (misal: "15 Agustus 2026" / "14 Agu 2026")
    final parts = clean
        .split(RegExp(r'[\s,\/\-]+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      // Coba pola d MMMM yyyy
      final day = int.tryParse(parts[0]);
      final monthKey = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]);
      if (day != null && year != null) {
        final month = _indonesianMonths[monthKey] ?? int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          return DateTime(year, month, day);
        }
      }

      // Coba pola yyyy MMMM d
      final yearFirst = int.tryParse(parts[0]);
      final monthMid =
          _indonesianMonths[parts[1].toLowerCase()] ?? int.tryParse(parts[1]);
      final dayLast = int.tryParse(parts[2]);
      if (yearFirst != null &&
          yearFirst > 1900 &&
          monthMid != null &&
          dayLast != null) {
        return DateTime(yearFirst, monthMid, dayLast);
      }
    }

    // 3. Fallback ke DateFormat
    final patterns = [
      'd MMMM yyyy',
      'd MMM yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
    ];
    for (final pattern in patterns) {
      try {
        final d = DateFormat(pattern, 'id').parse(clean);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
      try {
        final d = DateFormat(pattern).parse(clean);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }

    return null;
  }
}
