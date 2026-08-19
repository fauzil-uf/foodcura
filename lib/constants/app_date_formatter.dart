import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Utilitas formatting dan parsing tanggal/waktu standar Indonesia murni menggunakan package intl.
class AppDateFormatter {
  AppDateFormatter._();

  static bool _initialized = false;
  static void _init() {
    if (!_initialized) {
      initializeDateFormatting('id', null);
      _initialized = true;
    }
  }

  /// Format: "14 Agu 2026"
  static String formatShortDate([DateTime? date]) {
    _init();
    return DateFormat('d MMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format: "14 Agustus 2026"
  static String formatToday([DateTime? date]) {
    _init();
    return DateFormat('d MMMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format: "Sabtu, 15 Agu 2026"
  static String formatDayDate([DateTime? date]) {
    _init();
    return DateFormat('EEEE, d MMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format: "Agustus 2026"
  static String formatMonthYear([DateTime? date]) {
    _init();
    return DateFormat('MMMM yyyy', 'id').format(date ?? DateTime.now());
  }

  /// Format singkatan hari: "Sen", "Sel", "Rab"
  static String formatShortDayName([DateTime? date]) {
    _init();
    return DateFormat('EEE', 'id').format(date ?? DateTime.now());
  }

  /// Format jam: "14:30"
  static String formatTime([DateTime? date]) =>
      DateFormat('HH:mm').format(date ?? DateTime.now());

  /// Format tanggal & jam lengkap: "14 Agu 2026, 14:30"
  static String formatFullDateTime([DateTime? date]) {
    _init();
    return DateFormat('d MMM yyyy, HH:mm', 'id').format(date ?? DateTime.now());
  }

  /// Format relatif: "Baru saja ditambahkan", "5 menit lalu", "Hari ini, 14:30"
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

  /// Parse string tanggal ke [DateTime] murni menggunakan [intl] & ISO parser.
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final clean = dateStr.trim();
    _init();

    final iso = DateTime.tryParse(clean);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    const patterns = [
      'd MMMM yyyy',
      'd MMM yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'd MMMM yyyy, HH:mm',
      'd MMM yyyy, HH:mm',
    ];

    for (final pattern in patterns) {
      try {
        final d = DateFormat(pattern, 'id').parse(clean);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
      try {
        final d = DateFormat(pattern, 'en').parse(clean);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }
    return null;
  }
}

/// Extension ringkas untuk formatting langsung dari objek [DateTime].
extension AppDateTimeExt on DateTime {
  String toShortDate() => AppDateFormatter.formatShortDate(this);
  String toFullDate() => AppDateFormatter.formatToday(this);
  String toDayDate() => AppDateFormatter.formatDayDate(this);
  String toMonthYear() => AppDateFormatter.formatMonthYear(this);
  String toShortDay() => AppDateFormatter.formatShortDayName(this);
  String toRelativeTime() => AppDateFormatter.formatRelativeTime(this);
}

/// Extension untuk [DateTime] nullable dengan fallback otomatis.
extension AppNullableDateTimeExt on DateTime? {
  String toShortDate([String fallback = '-']) =>
      this != null ? AppDateFormatter.formatShortDate(this!) : fallback;
}

/// Extension untuk parsing cepat [String] ke [DateTime].
extension AppStringDateExt on String? {
  DateTime? toDateTime() => AppDateFormatter.parseDate(this);
}
